// @dart=2.9

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile/component/alert.dart';
import 'package:mobile/models/prepaid-denom.dart';
import 'package:mobile/provider/analitycs.dart';
import 'package:mobile/Products/seepays/layout/detail-denom.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/bloc/Bloc.dart' show bloc;
import 'package:mobile/bloc/Api.dart' show apiUrl;
import 'package:package_info_plus/package_info_plus.dart';

abstract class SeepaysDetailDenomController extends State<SeepaysDetailDenom>
    with TickerProviderStateMixin {
  List<PrepaidDenomModel> listDenom = [];
  String coverIcon = '';
  bool loading = true;
  bool failed = false;
  PrepaidDenomModel selectedDenom;
  TextEditingController tujuan = TextEditingController();
  TextEditingController nominal = TextEditingController();
  String packageName = '';
  List<String> suggestNumbers = [];
  bool loadingSuggest = false;
  final bool useApiSuggest = true; // set true untuk gunakan API

  @override
  void initState() {
    super.initState();
    _getPackageName();
    analitycs.pageView('/menu/transaksi/' + widget.menu.category_id, {
      'userId': bloc.userId.valueWrapper?.value,
      'title': 'Buka Menu ' + widget.menu.name
    });
    getData();
    getSuggestNumbers();
  }

  Future<void> _getPackageName() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      packageName = info.packageName;
    });
  }

  getData() async {
    http.Response response = await http.get(
        Uri.parse('$apiUrl/product/${widget.menu.category_id}'),
        headers: {'Authorization': bloc.token.valueWrapper?.value});

    if (response.statusCode == 200) {
      List<PrepaidDenomModel> lm = (jsonDecode(response.body)['data'] as List)
          .map((m) => PrepaidDenomModel.fromJson(m))
          .toList();

      // SET CATEGORY COVER ICON
      coverIcon = json.decode(response.body)['url_image'] ?? '';

      setState(() {
        listDenom = lm;
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
        listDenom = [];
      });
    }
  }

  onTapDenom(denom) {
    if (denom.note == 'gangguan') {
      ScaffoldMessenger.of(context).showSnackBar(
        Alert(
          'Produk sedang mengalami gangguan',
          isError: true,
        ),
      );
      return;
    }
    if (denom != null) {
      setState(() {
        selectedDenom = denom;
      });
    }
  }

  Future<void> getSuggestNumbers() async {
    // FITUR SUGGEST HISTORY NOMOR PEMBELI - EKSKLUSIF UNTUK APLIKASI SEEPAYS
    if (packageName != 'com.seepaysbiller.app') {
      setState(() {
        suggestNumbers = [];
      });
      return;
    }

    if (!useApiSuggest) {
      setState(() {
        suggestNumbers = _hardcodedSuggestionsForMenu(widget.menu.name);
      });
      return;
    }

    try {
      setState(() { loadingSuggest = true; });

      // Gunakan kategori ID untuk pulsa jika tersedia
      String apiEndpoint = '$apiUrl/trx/list?page=0&limit=50';
      if (widget.menu.category_id != null && widget.menu.category_id.isNotEmpty) {
        apiEndpoint = '$apiUrl/trx/list?page=0&limit=50&kategori_id=${widget.menu.category_id}';
      } else if (widget.menu.name.toLowerCase().contains('pulsa')) {
        // Fallback untuk pulsa jika category_id kosong
        apiEndpoint = '$apiUrl/trx/list?page=0&limit=50&kategori_id=685b71969a3036284f0d8fec';
      }
      
      print('🌐 Seepays API Endpoint: $apiEndpoint');
      
      final response = await http.get(
        Uri.parse(apiEndpoint),
        headers: { 'Authorization': bloc.token.valueWrapper?.value },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = json.decode(response.body);
        final List<dynamic> datas = (jsonBody['data'] ?? []) as List<dynamic>;

        // sort terbaru dulu
        datas.sort((a, b) {
          final String ac = (a['created_at'] ?? '');
          final String bc = (b['created_at'] ?? '');
          DateTime ad, bd;
          try { ad = DateTime.parse(ac); } catch (_) { ad = DateTime.fromMillisecondsSinceEpoch(0); }
          try { bd = DateTime.parse(bc); } catch (_) { bd = DateTime.fromMillisecondsSinceEpoch(0); }
          return bd.compareTo(ad);
        });

        final Set<String> allowedCodes = listDenom
            .map((e) => (e.kode_produk ?? '').toString())
            .where((e) => e.isNotEmpty)
            .toSet();

        final Set<String> uniqueTargets = <String>{};
        for (final dynamic item in datas) {
          final Map<String, dynamic> prod = (item['produk_id'] ?? {}) as Map<String, dynamic>;
          final String code = (prod['kode_produk'] ?? '').toString();
          final String name = (prod['nama'] ?? '').toString();
          final String tujuanItem = (item['tujuan'] ?? '').toString().trim();
          if (tujuanItem.isEmpty) continue;

          bool matchesMenu = true;
          if (allowedCodes.isNotEmpty) {
            matchesMenu = allowedCodes.contains(code);
          } else {
            final String menuName = (widget.menu.name ?? '').toLowerCase();
            final String n = name.toLowerCase();
            final String c = code.toLowerCase();
            if (menuName.contains('dana')) {
              matchesMenu = n.contains('dana') || c.contains('dana');
            } else if (menuName.contains('ovo')) {
              matchesMenu = n.contains('ovo') || c.contains('ovo');
            } else if (menuName.contains('gopay') || menuName.contains('gojek')) {
              matchesMenu = n.contains('gopay') || n.contains('gojek') || c.contains('gopay');
            } else if (menuName.contains('shopee')) {
              matchesMenu = n.contains('shopee') || c.contains('shopee');
            } else if (menuName.contains('mobile legends') || menuName.contains('ml') || menuName.contains('mlbb')) {
              matchesMenu = n.contains('mobile') || n.contains('legends') || c.contains('ml');
            } else if (menuName.contains('free fire') || menuName.contains('ff')) {
              matchesMenu = n.contains('free') || n.contains('fire') || c.contains('ff');
            }
          }

          if (matchesMenu) {
            uniqueTargets.add(tujuanItem);
            if (uniqueTargets.length >= 10) break;
          }
        }

        setState(() { suggestNumbers = uniqueTargets.toList(); });
      } else {
        setState(() { suggestNumbers = []; });
      }
    } catch (_) {
      setState(() { suggestNumbers = []; });
    } finally {
      setState(() { loadingSuggest = false; });
    }
  }

  List<String> _hardcodedSuggestionsForMenu(String menuName) {
    final String name = (menuName ?? '').toLowerCase();
    if (name.contains('dana')) {
      return ['085852076162', '081234567890', '088123456789', '087812345678'];
    } else if (name.contains('ovo')) {
      return ['081234567890', '081298765432', '082111223344'];
    } else if (name.contains('gopay') || name.contains('gojek')) {
      return ['085700112233', '085700223344', '085700334455'];
    } else if (name.contains('shopee')) {
      return ['081390001122', '081390002233', '081390003344'];
    } else if (name.contains('mobile legends') || name.contains('ml') || name.contains('mlbb')) {
      return ['100012345678', '200012345678', '300012345678'];
    } else if (name.contains('free fire') || name.contains('ff')) {
      return ['1212', '1213', '2'];
    } else if (name.contains('pubg')) {
      return ['555001122', '555002233', '555003344'];
    }
    return ['081234567890', '082112223333', '089512345678'];
  }
} 
// @dart=2.9
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile/component/alert.dart';
import 'package:mobile/models/prepaid-denom.dart';
import 'package:mobile/provider/analitycs.dart';
import './detail-denom.dart';
import 'package:http/http.dart' as http;
import '../../bloc/Bloc.dart' show bloc;
import '../../bloc/Api.dart' show apiUrl;
import 'package:package_info_plus/package_info_plus.dart';

abstract class DetailDenomController extends State<DetailDenom>
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
    print('=== DetailDenomController initState() START ===');
    print('Menu Name: ${widget.menu.name}');
    print('Menu Category ID: ${widget.menu.category_id}');
    
    print('Calling _getPackageName()...');
    _getPackageName().then((_) {
      print('✅ _getPackageName() completed, now calling getSuggestNumbers()...');
      getSuggestNumbers();
    });
    
    analitycs.pageView('/menu/transaksi/' + widget.menu.category_id, {
      'userId': bloc.userId.valueWrapper?.value,
      'title': 'Buka Menu ' + widget.menu.name
    });
    getData();
    print('getSuggestNumbers() scheduled (after _getPackageName)');
    print('=== DetailDenomController initState() END ===');
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
    print('=== DetailDenomController getSuggestNumbers() START ===');
    print('Package Name: $packageName');
    print('Menu Name: ${widget.menu.name}');
    print('Menu Category ID: ${widget.menu.category_id}');
    
    // FITUR SUGGEST HISTORY NOMOR PEMBELI - EKSKLUSIF UNTUK APLIKASI SEEPAYS DAN PAYUNIOVO
    if (packageName != 'com.seepaysbiller.app' && packageName != 'mobile.payuni.id' && packageName != 'co.payuni.id') {
      print('❌ Package name tidak didukung: $packageName');
      setState(() {
        suggestNumbers = [];
      });
      return;
    }
    
    print('✅ Package name didukung: $packageName');

    if (!useApiSuggest) {
      setState(() {
        suggestNumbers = _hardcodedSuggestionsForMenu(widget.menu.name);
      });
      return;
    }

    try {
      setState(() {
        loadingSuggest = true;
      });

      // API berbeda untuk Seepays vs Payuniovo
      String apiEndpoint;
      if (packageName == 'mobile.payuni.id' || packageName == 'co.payuni.id') {
        // API khusus Payuniovo
        apiEndpoint = 'https://payuni-app.findig.id/api/v1/trx/lastTransaction?kategori_id=${widget.menu.category_id}&limit=10&skip=0';
        print('🌐 Menggunakan API Payuniovo: $apiEndpoint');
      } else if (packageName == 'com.seepaysbiller.app') {
        // API khusus Seepays - menggunakan lastTransaction
        apiEndpoint = 'https://app.payuni.co.id/api/v1/trx/lastTransaction?kategori_id=${widget.menu.category_id}&limit=10&skip=0';
        print('🌐 Menggunakan API Seepays: $apiEndpoint');
      } else {
        // API default untuk produk lain - menggunakan /trx/list
        apiEndpoint = '$apiUrl/trx/list?page=0&limit=50';
        print('🌐 Menggunakan API Default: $apiEndpoint');
      }

      print('📡 Calling API...');
      final response = await http.get(
        Uri.parse(apiEndpoint),
        headers: {
          'Authorization': bloc.token.valueWrapper?.value,
        },
      );
      
      print('📡 Response Status: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> datas;
        String sortKey;
        
        if (packageName == 'mobile.payuni.id' || packageName == 'co.payuni.id' || packageName == 'com.seepaysbiller.app') {
          // Response Payuniovo dan Seepays langsung berupa array
          datas = json.decode(response.body) as List<dynamic>;
          sortKey = 'tanggal';
        } else {
          // Response produk lain nested dalam data
          final Map<String, dynamic> jsonBody = json.decode(response.body);
          datas = (jsonBody['data'] ?? []) as List<dynamic>;
          sortKey = 'created_at';
        }

        // Sort by key yang sesuai
        datas.sort((a, b) {
          final String ac = (a[sortKey] ?? '');
          final String bc = (b[sortKey] ?? '');
          DateTime ad, bd;
          try { ad = DateTime.parse(ac); } catch (_) { ad = DateTime.fromMillisecondsSinceEpoch(0); }
          try { bd = DateTime.parse(bc); } catch (_) { bd = DateTime.fromMillisecondsSinceEpoch(0); }
          return bd.compareTo(ad);
        });

        final Set<String> uniqueTargets = <String>{};

        if (packageName == 'mobile.payuni.id' || packageName == 'co.payuni.id' || packageName == 'com.seepaysbiller.app') {
          // Payuniovo dan Seepays: terima semua format (PLN ID, HP, dll)
          print('🔍 Processing Payuniovo/Seepays data...');
          for (final dynamic item in datas) {
            final String tujuanItem = (item['tujuan'] ?? '').toString().trim();
            print('🔍 Item tujuan: "$tujuanItem"');
            if (tujuanItem.isEmpty) {
              print('❌ Tujuan kosong, skip');
              continue;
            }

            if (tujuanItem.length >= 8 && tujuanItem.length <= 20) {
              print('✅ Tujuan valid, tambahkan: $tujuanItem');
              uniqueTargets.add(tujuanItem);
              if (uniqueTargets.length >= 5) break;
            } else {
              print('❌ Tujuan tidak valid (length: ${tujuanItem.length}): $tujuanItem');
            }
          }
          print('🔍 Total unique targets Payuniovo/Seepays: ${uniqueTargets.length}');
        } else {
          // Allowed product codes from current denom list
          final Set<String> allowedCodes = listDenom
              .map((e) => (e.kode_produk ?? '').toString())
              .where((e) => e.isNotEmpty)
              .toSet();

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
              // Heuristic: match by menu name keywords
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
        }

        print('🎯 Final suggest numbers: ${uniqueTargets.toList()}');
        setState(() {
          suggestNumbers = uniqueTargets.toList();
        });
      } else {
        print('❌ API response tidak berhasil: ${response.statusCode}');
        setState(() {
          suggestNumbers = [];
        });
      }
    } catch (error) {
      print('❌ Error dalam getSuggestNumbers: $error');
      setState(() {
        suggestNumbers = [];
      });
    } finally {
      print('🏁 Setting loadingSuggest = false');
      setState(() {
        loadingSuggest = false;
      });
    }
    print('=== DetailDenomController getSuggestNumbers() END ===');
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
    // default fallback
    return ['081234567890', '082112223333', '089512345678'];
  }
}

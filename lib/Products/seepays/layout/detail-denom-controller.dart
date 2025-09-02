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
    _getPackageName().then((_) {
      getData();
      getSuggestNumbers();
    });
    analitycs.pageView('/menu/transaksi/' + widget.menu.category_id, {
      'userId': bloc.userId.valueWrapper?.value,
      'title': 'Buka Menu ' + widget.menu.name
    });
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
    print('=== Seepays Detail Denom getSuggestNumbers() START ===');
    print('🔍 Package Name: $packageName');
    print('🔍 Menu Name: ${widget.menu.name}');
    print('🔍 Menu Kode Produk: ${widget.menu.kodeProduk}');
    print('🔍 Category ID: ${widget.menu.category_id}');
    print('🔍 Use API Suggest: $useApiSuggest');
    print('🔍 API URL: $apiUrl');
    
    // FITUR SUGGEST HISTORY NOMOR PEMBELI - EKSKLUSIF UNTUK APLIKASI SEEPAYS
    if (packageName != 'com.seepaysbiller.app') {
      print('❌ Not Seepays, skipping suggest numbers');
      setState(() {
        suggestNumbers = [];
      });
      return;
    }

    print('✅ Seepays detected, proceeding with suggest numbers');

    if (!useApiSuggest) {
      print('📋 Using hardcoded suggestions');
      setState(() {
        suggestNumbers = _hardcodedSuggestionsForMenu(widget.menu.name);
      });
      return;
    }

    print('🌐 Using API suggestions');

    try {
      setState(() { loadingSuggest = true; });

      // Gunakan kategori ID untuk pulsa jika tersedia
      String finalCategoryId = widget.menu.category_id ?? '';
      
      print('🔍 Final Category ID before check: "$finalCategoryId"');
      
      if (finalCategoryId.isEmpty || finalCategoryId == 'null') {
        print('⚠️ Category ID kosong atau null, menampilkan pesan "Belum pernah transaksi"');
        setState(() { 
          suggestNumbers = ['Belum pernah transaksi di produk ini']; 
          loadingSuggest = false;
        });
        return;
      }
      
      String apiEndpoint = '$apiUrl/trx/lastTransaction?kategori_id=$finalCategoryId&limit=10&skip=0';
      
      print('🌐 Seepays API Endpoint: $apiEndpoint');
      print('🔍 Category ID: ${widget.menu.category_id}');
      
      final response = await http.get(
        Uri.parse(apiEndpoint),
        headers: { 'Authorization': bloc.token.valueWrapper?.value },
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Response lastTransaction langsung berupa array
        final List<dynamic> datas = json.decode(response.body) as List<dynamic>;
        print('📊 Found ${datas.length} transactions in response');

        if (datas.isEmpty) {
          print('📭 No transactions found for category: ${widget.menu.category_id}');
          setState(() { 
            suggestNumbers = ['Belum pernah transaksi di produk ini']; 
          });
          return;
        }

        // sort terbaru dulu berdasarkan tanggal
        datas.sort((a, b) {
          final String ac = (a['tanggal'] ?? '');
          final String bc = (b['tanggal'] ?? '');
          DateTime ad, bd;
          try { ad = DateTime.parse(ac); } catch (_) { ad = DateTime.fromMillisecondsSinceEpoch(0); }
          try { bd = DateTime.parse(bc); } catch (_) { bd = DateTime.fromMillisecondsSinceEpoch(0); }
          return bd.compareTo(ad);
        });

        final Set<String> uniqueTargets = <String>{};
        for (final dynamic item in datas) {
          final String tujuanItem = (item['tujuan'] ?? '').toString().trim();
          print('🔍 Processing item: $tujuanItem');
          if (tujuanItem.isEmpty) continue;

          // Terima semua format yang valid (HP, PLN ID, dll)
          if (tujuanItem.length >= 8 && tujuanItem.length <= 20) {
            uniqueTargets.add(tujuanItem);
            print('✅ Added to suggestions: $tujuanItem');
            if (uniqueTargets.length >= 10) break;
          } else {
            print('❌ Skipped (invalid length): $tujuanItem');
          }
        }

        setState(() { 
          suggestNumbers = uniqueTargets.toList(); 
        });
        print('✅ Final suggest numbers: $suggestNumbers');
      } else {
        print('❌ API failed with status: ${response.statusCode}');
        setState(() { 
          suggestNumbers = ['Belum pernah transaksi di produk ini']; 
        });
      }
    } catch (error) {
      print('❌ Error dalam getSuggestNumbers: $error');
      setState(() { 
        suggestNumbers = ['Belum pernah transaksi di produk ini']; 
      });
    } finally {
      setState(() { loadingSuggest = false; });
    }
    
    print('=== Seepays Detail Denom getSuggestNumbers() END ===');
  }

  List<String> _hardcodedSuggestionsForMenu(String menuName) {
    print('🔍 _hardcodedSuggestionsForMenu called for: $menuName');
    final String name = (menuName ?? '').toLowerCase();
    print('🔍 Normalized menu name: $name');
    
    if (name.contains('dana')) {
      print('✅ Returning Dana suggestions');
      return ['085852076162', '081234567890', '088123456789', '087812345678'];
    } else if (name.contains('ovo')) {
      print('✅ Returning OVO suggestions');
      return ['081234567890', '081298765432', '082111223344'];
    } else if (name.contains('gopay') || name.contains('gojek')) {
      print('✅ Returning Gopay suggestions');
      return ['085700112233', '085700223344', '085700334455'];
    } else if (name.contains('shopee')) {
      print('✅ Returning Shopee suggestions');
      return ['081390001122', '081390002233', '081390003344'];
    } else if (name.contains('mobile legends') || name.contains('ml') || name.contains('mlbb')) {
      print('✅ Returning MLBB suggestions');
      return ['100012345678', '200012345678', '300012345678'];
    } else if (name.contains('free fire') || name.contains('ff')) {
      print('✅ Returning Free Fire suggestions');
      return ['1212', '1213', '2'];
    } else if (name.contains('pubg')) {
      print('✅ Returning PUBG suggestions');
      return ['555001122', '555002233', '555003344'];
    } else if (name.contains('pln')) {
      print('✅ Returning PLN suggestions');
      return ['123456789', '987654321'];
    }
    print('⚠️ No specific suggestions found, returning default');
    return ['081234567890', '082112223333', '089512345678'];
  }
} 
// @dart=2.9

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile/component/alert.dart';
import 'package:mobile/provider/analitycs.dart';
import 'package:mobile/Products/seepays/layout/detail-denom-postpaid.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/bloc/Bloc.dart' show bloc;
import 'package:mobile/bloc/Api.dart' show apiUrl;
import 'package:package_info_plus/package_info_plus.dart';

abstract class SeepaysDetailDenomPostpaidController extends State<SeepaysDetailDenomPostpaid>
    with TickerProviderStateMixin {
  List<dynamic> listDenom = [];
  String menuLogo = '';
  bool loading = true;
  bool failed = false;
  dynamic selectedDenom;
  TextEditingController tujuan = TextEditingController();
  String packageName = '';
  List<String> suggestNumbers = [];
  bool loadingSuggest = false;
  String categoryId = ''; // Tambahkan variabel untuk menyimpan category_id
  
  @override
  void initState() {
    super.initState();
    _getPackageName().then((_) {
      getData().then((_) {
        getSuggestNumbers();
      });
    });
    analitycs.pageView('/menu/transaksi/' + widget.menu.kodeProduk, {
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

  Future<void> getSuggestNumbers() async {
    print('=== Seepays Postpaid getSuggestNumbers() START ===');
    print('🔍 Package Name: $packageName');
    print('🔍 Menu Name: ${widget.menu.name}');
    print('🔍 Menu Kode Produk: ${widget.menu.kodeProduk}');
    print('🔍 Category ID from widget: ${widget.menu.category_id}');
    print('🔍 Category ID from API: $categoryId');
    print('🔍 API URL: $apiUrl');
    
    if (packageName != 'com.seepaysbiller.app') {
      print('❌ Not Seepays, skipping suggest numbers');
      return;
    }

    print('✅ Seepays detected, proceeding with suggest numbers');

    try {
      setState(() {
        loadingSuggest = true;
      });

      // Gunakan categoryId dari API jika tersedia, jika tidak gunakan dari widget
      String finalCategoryId = categoryId.isNotEmpty ? categoryId : (widget.menu.category_id ?? '');
      String apiEndpoint = '$apiUrl/trx/lastTransaction?kategori_id=$finalCategoryId&limit=10&skip=0';
      
      if (finalCategoryId.isEmpty) {
        // Fallback untuk postpaid jika category_id kosong
        apiEndpoint = '$apiUrl/trx/lastTransaction?kategori_id=685b71969a3036284f0d8fec&limit=10&skip=0';
        print('⚠️ Category ID kosong, menggunakan fallback');
      }
      
      print('🌐 Seepays Postpaid API Endpoint: $apiEndpoint');
      print('🔍 Final Category ID: $finalCategoryId');
      
      final response = await http.get(
        Uri.parse(apiEndpoint),
        headers: {
          'Authorization': bloc.token.valueWrapper?.value,
        },
      );
      
      print('📡 Response Status: ${response.statusCode}');
      print('📡 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Response lastTransaction langsung berupa array
        final List<dynamic> datas = json.decode(response.body) as List<dynamic>;
        print('📊 Found ${datas.length} transactions in response');

        if (datas.isEmpty) {
          print('📭 No transactions found for category: $finalCategoryId');
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
      setState(() {
        loadingSuggest = false;
      });
    }
    
    print('=== Seepays Postpaid getSuggestNumbers() END ===');
  }

  void selectSuggestNumber(String number) {
    setState(() {
      tujuan.text = number;
    });
    print('✅ Seepays Postpaid: Selected suggest number: $number');
  }

  Future<void> getData() async {
    http.Response response = await http.get(
        Uri.parse('$apiUrl/product/${widget.menu.kodeProduk}'),
        headers: {'Authorization': bloc.token.valueWrapper?.value});

    if (response.statusCode == 200) {
      List<dynamic> lm = (jsonDecode(response.body)['data'] as List);

      // SET MENU LOGO
      menuLogo = json.decode(response.body)['url_image'] ?? '';
      
      // SET CATEGORY ID dari response
      if (lm.isNotEmpty) {
        categoryId = lm.first['category_id'] ?? '';
        print('🔍 Seepays Postpaid: Category ID from API: $categoryId');
      }

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
    if (denom['note'] == 'gangguan') {
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

  inquiryPostpaid(String kodeProduk, String tujuan) async {
    setState(() {
      loading = true;
    });

    try {
      http.Response response = await http.post(
        Uri.parse('$apiUrl/trx/postpaid/inquiry'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': bloc.token.valueWrapper?.value,
        },
        body: json.encode({
          'kode_produk': kodeProduk,
          'tujuan': tujuan,
          'counter': 1,
        }),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body)['data'];
        setState(() {
          selectedDenom = data;
          loading = false;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tagihan berhasil ditemukan'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        String message = json.decode(response.body)['message'] ?? 
            'Terjadi kesalahan saat mengambil data tagihan';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        loading = false;
      });
    }
  }
} 
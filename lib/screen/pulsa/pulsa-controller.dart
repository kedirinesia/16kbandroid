// @dart=2.9
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile/component/alert.dart';
import 'package:mobile/models/pulsa.dart';
import 'package:mobile/screen/pulsa/pulsa.dart';
import 'package:http/http.dart' as http;
import '../../bloc/Bloc.dart' show bloc;
import '../../bloc/Api.dart' show apiUrl;
import 'package:package_info_plus/package_info_plus.dart';

abstract class PulsaController extends State<Pulsa>
    with TickerProviderStateMixin {
  List<PulsaModel> listDenom = [];
  bool loading = false;
  bool failed = false;
  String prefixNomor = "";
  PulsaModel selectedDenom;
  TextEditingController nomorHp = TextEditingController();
  String packageName = '';
  List<String> suggestNumbers = [];
  bool loadingSuggest = false;

  @override
  void initState() {
    super.initState();
    print('=== PulsaController initState() START ===');
    print('Menu Name: ${widget.menuModel.name}');
    print('Menu Category ID: ${widget.menuModel.category_id}');
    
    print('Calling _getPackageName()...');
    _getPackageName().then((_) {
      print('✅ _getPackageName() completed, now calling getSuggestNumbers()...');
      getSuggestNumbers();
    });
    
    print('getSuggestNumbers() scheduled (after _getPackageName)');
    print('=== PulsaController initState() END ===');
  }

  Future<void> _getPackageName() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      packageName = info.packageName;
    });
  }

  Future<void> getSuggestNumbers() async {
    print('=== PulsaController getSuggestNumbers() START ===');
    print('Package Name: $packageName');
    print('Menu Name: ${widget.menuModel.name}');
    print('Menu Category ID: ${widget.menuModel.category_id}');
    
    // FITUR SUGGEST HISTORY NOMOR PEMBELI - EKSKLUSIF UNTUK APLIKASI SEEPAYS DAN PAYUNIOVO
    if (packageName != 'com.seepaysbiller.app' && packageName != 'mobile.payuni.id' && packageName != 'co.payuni.id') {
      print('❌ Package name tidak didukung: $packageName');
      setState(() {
        suggestNumbers = [];
      });
      return;
    }
    
    print('✅ Package name didukung: $packageName');

    try {
      setState(() {
        loadingSuggest = true;
      });

      // API berbeda untuk Seepays vs Payuniovo
      String apiEndpoint;
      
      // Untuk menu PULSA, gunakan kategori_id default jika kosong
      String kategoriId = widget.menuModel.category_id;
      if (kategoriId == null || kategoriId.isEmpty) {
        // Fallback untuk menu PULSA - gunakan kategori default sesuai package
        if (packageName == 'mobile.payuni.id' || packageName == 'co.payuni.id') {
          kategoriId = '5eb704e8c78b5393e4ab3fe6'; // Kategori default untuk Payuniovo
        } else {
          kategoriId = '685b71969a3036284f0d8fec'; // Kategori default untuk Seepays
        }
        print('⚠️ Category ID kosong, menggunakan fallback: $kategoriId');
      }
      
      if (packageName == 'mobile.payuni.id' || packageName == 'co.payuni.id') {
        // API khusus Payuniovo
        // Gunakan kategori ID yang sudah di-fallback
        apiEndpoint = 'https://payuni-app.findig.id/api/v1/trx/lastTransaction?kategori_id=$kategoriId&limit=5&skip=0';
        print('🌐 Menggunakan API Payuniovo dengan kategori: $apiEndpoint');
      } else if (packageName == 'com.seepaysbiller.app') {
        // API khusus Seepays - menggunakan lastTransaction
        apiEndpoint = 'https://app.payuni.co.id/api/v1/trx/lastTransaction?kategori_id=$kategoriId&limit=5&skip=0';
        print('🌐 Menggunakan API Seepays dengan kategori: $apiEndpoint');
      } else {
        // API default untuk produk lain
        if (kategoriId.isNotEmpty) {
          apiEndpoint = '$apiUrl/trx/list?page=0&limit=50&kategori_id=$kategoriId';
          print('🌐 Menggunakan API Default dengan kategori: $apiEndpoint');
        } else {
          apiEndpoint = '$apiUrl/trx/list?page=0&limit=50';
          print('🌐 Menggunakan API Default tanpa kategori: $apiEndpoint');
        }
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
              .map((e) => (e.kodeProduk ?? '').toString())
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
              final String menuName = (widget.menuModel.name ?? '').toLowerCase();
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
    print('=== PulsaController getSuggestNumbers() END ===');
  }

  void selectSuggestNumber(String number) {
    print('🎯 Suggest number diklik: $number');
    setState(() {
      nomorHp.text = number;
    });
    
    // Auto-load denom setelah nomor diisi
    if (number.length >= 4 && number.startsWith('08')) {
      print('🚀 Auto-loading denom untuk nomor: $number');
      
      // Reset state
      setState(() {
        listDenom.clear();
        prefixNomor = number.substring(0, 4);
        loading = true;
      });
      
      // Load denom
      getDenom(number);
    } else {
      print('⚠️ Nomor tidak valid untuk auto-load denom: $number');
    }
  }

  void getDenom(String nomor) async {
    setState(() {
      loading = true;
    });

    http.Response response = await http.get(
        Uri.parse('$apiUrl/product/pulsa?q=$nomor'),
        headers: {'Authorization': bloc.token.valueWrapper?.value});

    if (response.statusCode == 200) {
      List<PulsaModel> list = (json.decode(response.body)['data'] as List)
          .map((item) => PulsaModel.fromJson(item))
          .toList();
      listDenom = list;
    }

    setState(() {
      loading = false;
    });
  }

  void selectDenom(PulsaModel denom) {
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
}

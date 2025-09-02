// @dart=2.9

import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/bloc/Bloc.dart';
import 'package:mobile/bloc/ConfigApp.dart';    
import 'package:mobile/bloc/TemplateConfig.dart';
import 'package:mobile/bloc/Api.dart';
import 'package:mobile/component/contact.dart';
import 'package:mobile/component/alert.dart';
import 'package:mobile/config.dart';
import 'package:mobile/models/menu.dart'; 
import 'package:mobile/models/pulsa.dart';
import 'package:mobile/models/favorite_number.dart';
import 'package:mobile/models/transaction_history.dart';
import 'package:mobile/modules.dart';
import 'package:mobile/provider/analitycs.dart';
import 'package:mobile/screen/transaksi/inquiry_prepaid.dart';
import 'package:mobile/screen/favorite-number/favorite-number.dart';
import '../config.dart' as seepays_config;

class Pulsa extends StatefulWidget {
  final MenuModel menuModel;

  Pulsa(this.menuModel);

  @override
  _PulsaState createState() => _PulsaState();
}

class _PulsaState extends State<Pulsa> with TickerProviderStateMixin {
  bool logoAppCover = false;
  bool logoProductMenuCover = false;
  String operatorIcon = '';
  bool activateContact = true;
  
  // Properties from PulsaController
  List<PulsaModel> listDenom = [];
  bool loading = false;
  bool failed = false;
  String prefixNomor = "";
  PulsaModel selectedDenom;
  TextEditingController nomorHp = TextEditingController();
  
  // Transaction history properties
  List<TransactionHistoryModel> transactionHistory = [];
  List<TransactionHistoryModel> recentTransactions = [];
  bool loadingHistory = false;

  @override
  void initState() {
    super.initState();
    analitycs.pageView('/pulsa', {
      'userId': bloc.userId.valueWrapper?.value,
      'title': 'Pulsa',
    });
    // Load transaction history
    print('🔄 Seepays: Loading transaction history on init...');
    loadTransactionHistory();
    
    // Add listener untuk menangani paste event
    nomorHp.addListener(() {
      if (nomorHp.text.isNotEmpty && nomorHp.text.length >= 4) {
        _handleNumberInput(nomorHp.text);
      }
    });
  }

  // Methods from PulsaController
  void getDenom(String nomor) async {
    setState(() {
      loading = true;
    });

    http.Response response = await http.get(
        Uri.parse('${seepays_config.apiUrl}/product/pulsa?q=$nomor'),
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

  // Helper function untuk menangani input nomor (termasuk paste)
  void _handleNumberInput(String str) {
    print('🔢 Seepays: Handling number input: $str');
    
    if (str.length >= 4 && str.startsWith('08')) {
      String newPrefix = str.substring(0, 4);
      print('📱 Seepays: Detected prefix: $newPrefix, current prefix: $prefixNomor');
      
      if (newPrefix != prefixNomor) {
        print('🔄 Seepays: Prefix changed, updating operator logo and fetching denom');
        setState(() {
          listDenom.clear();
          prefixNomor = newPrefix;
          loading = true;
          // Enable logo product menu cover untuk Seepays
          logoProductMenuCover = true;
        });
        getDenom(str);
      } else {
        print('ℹ️ Seepays: Same prefix, no update needed');
      }
    } else {
      print('❌ Seepays: Invalid number format or too short');
    }
  }

  @override
  void dispose() {
    nomorHp.dispose();
    super.dispose();
  }

  // Load transaction history
  Future<void> loadTransactionHistory() async {
    setState(() {
      loadingHistory = true;
    });

    // Simulate API delay for testing
    await Future.delayed(Duration(milliseconds: 1000));

    try {
      // HARDCODED DATA UNTUK TESTING - COMMENT KODE DI BAWAH UNTUK MENGGUNAKAN API ASLI
      // ================================================================================
      
      // // Hardcoded transaction history untuk testing seepays customer history
      // List<Map<String, dynamic>> hardcodedData = [
      //   {
      //     '_id': '1',
      //     'status': 2, // Success
      //     'admin': 0,
      //     'counter': 1,
      //     'tujuan': '081234567890',
      //     'produk_id': {
      //       '_id': 'prod1',
      //       'name': 'Pulsa Telkomsel',
      //       'type': 2, // Pulsa/PPOB
      //       'icon': 'https://ayoba.co.id/dokumen/provider/tsel.png',
      //       'category': 'pulsa',
      //     },
      //     'harga_jual': 10000,
      //     'sn': 'SN001',
      //     'payment_by': 'saldo',
      //     'payment_id': 'PAY001',
      //     'created_at': '2024-01-15T10:30:00Z',
      //     'updated_at': '2024-01-15T10:35:00Z',
      //     'keterangan': 'Pulsa Telkomsel 10K',
      //     'poin': 10,
      //     'print': [],
      //   },
      //   {
      //     '_id': '2',
      //     'status': 2, // Success
      //     'admin': 0,
      //     'counter': 1,
      //     'tujuan': '085678901234',
      //     'produk_id': {
      //       '_id': 'prod2',
      //       'name': 'Pulsa Indosat',
      //       'type': 2, // Pulsa/PPOB
      //       'icon': 'https://ayoba.co.id/dokumen/provider/indosat.png',
      //       'category': 'pulsa',
      //     },
      //     'harga_jual': 25000,
      //     'sn': 'SN002',
      //     'payment_by': 'saldo',
      //     'payment_id': 'PAY002',
      //     'created_at': '2024-01-14T15:20:00Z',
      //     'updated_at': '2024-01-14T15:25:00Z',
      //     'keterangan': 'Pulsa Indosat 25K',
      //     'poin': 25,
      //     'print': [],
      //   },
      //   {
      //     '_id': '3',
      //     'status': 2, // Success
      //     'admin': 0,
      //     'counter': 1,
      //     'tujuan': '081112223334',
      //     'produk_id': {
      //       '_id': 'prod3',
      //       'name': 'Pulsa XL',
      //       'type': 2, // Pulsa/PPOB
      //       'icon': 'https://ayoba.co.id/dokumen/provider/xl.png',
      //       'category': 'pulsa',
      //     },
      //     'harga_jual': 50000,
      //     'sn': 'SN003',
      //     'payment_by': 'saldo',
      //     'payment_id': 'PAY003',
      //     'created_at': '2024-01-13T09:15:00Z',
      //     'updated_at': '2024-01-13T09:20:00Z',
      //     'keterangan': 'Pulsa XL 50K',
      //     'poin': 50,
      //     'print': [],
      //   },
      //   {
      //     '_id': '4',
      //     'status': 2, // Success
      //     'admin': 0,
      //     'counter': 1,
      //     'tujuan': '089876543210',
      //     'produk_id': {
      //       '_id': 'prod4',
      //       'name': 'Pulsa Three',
      //       'type': 2, // Pulsa/PPOB
      //       'icon': 'https://ayoba.co.id/dokumen/provider/three.png',
      //       'category': 'pulsa',
      //     },
      //     'harga_jual': 20000,
      //     'sn': 'SN004',
      //     'payment_by': 'saldo',
      //     'payment_id': 'PAY004',
      //     'created_at': '2024-01-12T14:45:00Z',
      //     'updated_at': '2024-01-12T14:50:00Z',
      //     'keterangan': 'Pulsa Three 20K',
      //     'poin': 20,
      //     'print': [],
      //   },
      //   {
      //     '_id': '5',
      //     'status': 2, // Success
      //     'admin': 0,
      //     'counter': 1,
      //     'tujuan': '088112233445',
      //     'produk_id': {
      //       '_id': 'prod5',
      //       'name': 'Pulsa Smartfren',
      //       'type': 2, // Pulsa/PPOB
      //       'icon': 'https://ayoba.co.id/dokumen/provider/smart.png',
      //       'category': 'pulsa',
      //     },
      //     'harga_jual': 15000,
      //     'sn': 'SN005',
      //     'payment_by': 'saldo',
      //     'payment_id': 'PAY005',
      //     'created_at': '2024-01-11T11:30:00Z',
      //     'updated_at': '2024-01-11T11:35:00Z',
      //     'keterangan': 'Pulsa Smartfren 15K',
      //     'poin': 15,
      //     'print': [],
      //   },
      // ];

      // Convert hardcoded data to TransactionHistoryModel
      // List<TransactionHistoryModel> hardcodedHistory = hardcodedData
      //     .map((json) => TransactionHistoryModel.fromJson(json))
      //     .toList();
      
      // setState(() {
      //   transactionHistory = hardcodedHistory;
      //   // Get recent successful transactions for pulsa/ppob
      //   recentTransactions = hardcodedHistory
      //       .where((trx) => 
      //           trx.status == 2 && // Successful transactions only
      //           trx.tujuan.isNotEmpty &&
      //           trx.tujuan.startsWith('08') && // Indonesian phone numbers
      //           trx.produkId?.type == 2) // Pulsa/PPOB products
      //       .take(3) // Show only 3 most recent
      //       .toList();
      // });
      
      // print('Loaded ${recentTransactions.length} recent transactions for testing');
      
      
      // ================================================================================
      // ================================================================================
      // DUMMY DATA UNTUK TESTING - COMMENT UNTUK MENGGUNAKAN API ASLI
      // ================================================================================
      // List<Map<String, dynamic>> hardcodedData = [
      //   {
      //     '_id': '1',
      //     'status': 2, // Success
      //     'admin': 0,
      //     'counter': 1,
      //     'tujuan': '081234567890',
      //     'produk_id': {
      //       '_id': 'prod1',
      //       'name': 'Pulsa Telkomsel',
      //       'type': 2, // Pulsa/PPOB
      //       'icon': 'https://ayoba.co.id/dokumen/provider/tsel.png',
      //       'category': 'pulsa',
      //     },
      //     'harga_jual': 25000,
      //     'sn': 'SN001',
      //     'payment_by': 'saldo',
      //     'payment_id': 'PAY001',
      //     'created_at': '2024-01-15T10:30:00Z',
      //     'updated_at': '2024-01-15T10:35:00Z',
      //     'keterangan': 'Pulsa Telkomsel 25K',
      //     'poin': 25,
      //     'print': [],
      //   },
      //   {
      //     '_id': '2',
      //     'status': 2, // Success
      //     'admin': 0,
      //     'counter': 1,
      //     'tujuan': '4321', // Dummy data untuk nomor 4321
      //     'produk_id': {
      //       '_id': 'prod2',
      //       'name': 'Pulsa Indosat',
      //       'type': 2, // Pulsa/PPOB
      //       'icon': 'https://ayoba.co.id/dokumen/provider/indosat.png',
      //       'category': 'pulsa',
      //     },
      //     'harga_jual': 20000,
      //     'sn': 'SN002',
      //     'payment_by': 'saldo',
      //     'payment_id': 'PAY002',
      //     'created_at': '2024-01-14T15:20:00Z',
      //     'updated_at': '2024-01-14T15:25:00Z',
      //     'keterangan': 'Pulsa Indosat 20K',
      //     'poin': 20,
      //     'print': [],
      //   },
      //   {
      //     '_id': '3',
      //     'status': 2, // Success
      //     'admin': 0,
      //     'counter': 1,
      //     'tujuan': '085876543210',
      //     'produk_id': {
      //       '_id': 'prod3',
      //       'name': 'Pulsa Three',
      //       'type': 2, // Pulsa/PPOB
      //       'icon': 'https://ayoba.co.id/dokumen/provider/three.png',
      //       'category': 'pulsa',
      //     },
      //     'harga_jual': 15000,
      //     'sn': 'SN003',
      //     'payment_by': 'saldo',
      //     'payment_id': 'PAY003',
      //     'created_at': '2024-01-13T12:15:00Z',
      //     'updated_at': '2024-01-13T12:20:00Z',
      //     'keterangan': 'Pulsa Three 15K',
      //     'poin': 15,
      //     'print': [],
      //   },
      //   {
      //     '_id': '4',
      //     'status': 2, // Success
      //     'admin': 0,
      //     'counter': 1,
      //     'tujuan': '4321', // Dummy data kedua untuk nomor 4321
      //     'produk_id': {
      //       '_id': 'prod4',
      //       'name': 'Pulsa XL',
      //       'type': 2, // Pulsa/PPOB
      //       'icon': 'https://ayoba.co.id/dokumen/provider/xl.png',
      //       'category': 'pulsa',
      //     },
      //     'harga_jual': 30000,
      //     'sn': 'SN004',
      //     'payment_by': 'saldo',
      //     'payment_id': 'PAY004',
      //     'created_at': '2024-01-12T14:45:00Z',
      //     'updated_at': '2024-01-12T14:50:00Z',
      //     'keterangan': 'Pulsa XL 30K',
      //     'poin': 30,
      //     'print': [],
      //   },
      //   {
      //     '_id': '5',
      //     'status': 2, // Success
      //     'admin': 0,
      //     'counter': 1,
      //     'tujuan': '088112233445',
      //     'produk_id': {
      //       '_id': 'prod5',
      //       'name': 'Pulsa Smartfren',
      //       'type': 2, // Pulsa/PPOB
      //       'icon': 'https://ayoba.co.id/dokumen/provider/smart.png',
      //       'category': 'pulsa',
      //     },
      //     'harga_jual': 15000,
      //     'sn': 'SN005',
      //     'payment_by': 'saldo',
      //     'payment_id': 'PAY005',
      //     'created_at': '2024-01-11T11:30:00Z',
      //     'updated_at': '2024-01-11T11:35:00Z',
      //     'keterangan': 'Pulsa Smartfren 15K',
      //     'poin': 15,
      //     'print': [],
      //   },
      // ];

      // // Convert hardcoded data to TransactionHistoryModel
      // List<TransactionHistoryModel> hardcodedHistory = hardcodedData
      //     .map((json) => TransactionHistoryModel.fromJson(json))
      //     .toList();
      
      // setState(() {
      //     transactionHistory = hardcodedHistory;
      //     // Filter transaksi pulsa berdasarkan description yang mengandung "Pulsa"
      //     recentTransactions = hardcodedHistory
      //         .where((trx) => 
      //             trx.status == 2 && // Transaksi sukses saja
      //             trx.tujuan.isNotEmpty &&
      //             (trx.tujuan.startsWith('08') || trx.tujuan == '4321') && // Include 4321
      //             _isPulsaProduct(trx) // Filter produk pulsa berdasarkan description
      //         )
      //         .take(5) // Tampilkan 5 transaksi terbaru
      //         .toList();
      // });
      
      // print('Loaded ${recentTransactions.length} recent pulsa transactions');
      // print('Filtered using pulsa description filter');
      
      // ================================================================================
      // KODE API BARU - MENGGUNAKAN API LAST TRANSACTION UNTUK SUGGEST HISTORY
      // ================================================================================
      // Gunakan kategori ID untuk pulsa jika tersedia
      String apiEndpoint = '${seepays_config.apiUrl}/trx/lastTransaction?kategori_id=${widget.menuModel.category_id}&limit=10&skip=0';
      if (widget.menuModel.category_id == null || widget.menuModel.category_id.isEmpty) {
        // Fallback untuk pulsa jika category_id kosong
        apiEndpoint = '${seepays_config.apiUrl}/trx/lastTransaction?kategori_id=685b71969a3036284f0d8fec&limit=10&skip=0';
      }
      
      print('🌐 Seepays API Endpoint: $apiEndpoint');
      print('🔍 Category ID: ${widget.menuModel.category_id}');
      
      http.Response response = await http.get(
        Uri.parse(apiEndpoint),
        headers: {'Authorization': bloc.token.valueWrapper?.value},
      );

      if (response.statusCode == 200) {
        print('✅ Seepays: API Response received successfully');
        print('API Response: ${response.body}');
        
        try {
          // Parse response dari API lastTransaction dengan error handling
          dynamic responseData = json.decode(response.body);
          List<dynamic> datas = [];
          
          // Handle response format sesuai dengan API lastTransaction
          if (responseData is List) {
            // Format: [...] (langsung array) - untuk lastTransaction
            datas = responseData;
            print('📋 Seepays: Response format: Direct array (lastTransaction)');
          } else if (responseData is Map<String, dynamic>) {
            // Format: {"status": 200, "data": [...]} - fallback untuk list
            datas = responseData['data'] ?? [];
            print('📋 Seepays: Response format: Map with data array (fallback)');
          } else {
            print('⚠️ Seepays: Unexpected response format: ${responseData.runtimeType}');
            datas = [];
          }
          
          print('📊 Seepays: Found ${datas.length} transactions in response');

          if (datas.isEmpty) {
            print('📭 Seepays: No transactions found for category: ${widget.menuModel.category_id}');
            setState(() {
              recentTransactions = [TransactionHistoryModel(tujuan: 'Belum pernah transaksi di produk ini')];
            });
            return;
          }
          print('📋 Seepays: Response data type: ${responseData.runtimeType}');
          
          if (datas.isNotEmpty) {
            print('🔍 Seepays: Parsing ${datas.length} items...');
            print('🔍 Seepays: First item: ${datas.first}');
            
            List<TransactionHistoryModel> apiHistory = [];
            for (int i = 0; i < datas.length; i++) {
              try {
                // Konversi field 'tanggal' ke 'created_at' untuk kompatibilitas
                Map<String, dynamic> item = Map<String, dynamic>.from(datas[i]);
                if (item.containsKey('tanggal') && !item.containsKey('created_at')) {
                  item['created_at'] = item['tanggal'];
                }
                
                TransactionHistoryModel trx = TransactionHistoryModel.fromJson(item);
                apiHistory.add(trx);
                print('✅ Seepays: Successfully parsed item $i: ${trx.tujuan}');
              } catch (e) {
                print('❌ Seepays: Error parsing item $i: $e');
                print('❌ Seepays: Raw item: ${datas[i]}');
              }
            }
            
            setState(() {
              transactionHistory = apiHistory;
              
              // Filter transaksi pulsa - untuk lastTransaction, terima semua karena sudah difilter di API
              print('🔍 Seepays: Filtering ${apiHistory.length} transactions...');
              recentTransactions = apiHistory
                  .where((trx) {
                    bool isValid = trx.tujuan.isNotEmpty && trx.tujuan.startsWith('08');
                    print('🔍 Seepays: Transaction ${trx.tujuan} - isValid: $isValid');
                    return isValid;
                  })
                  .take(10) // Tampilkan sampai 10 transaksi terbaru sesuai limit API
                  .toList();
            });
            
            print('🎯 Seepays: Filtered to ${recentTransactions.length} recent pulsa transactions');
            print('📱 Seepays: Recent transactions: ${recentTransactions.map((t) => t.tujuan).toList()}');
          } else {
            print('📭 Seepays: No transactions found in response');
            setState(() {
              recentTransactions = [TransactionHistoryModel(tujuan: 'Belum pernah transaksi di produk ini')];
            });
          }
          
        } catch (parseError) {
          print('❌ Seepays: Error parsing API response: $parseError');
          print('🔍 Seepays: Raw response: ${response.body}');
          
          // Tampilkan pesan error
          setState(() {
            recentTransactions = [TransactionHistoryModel(tujuan: 'Belum pernah transaksi di produk ini')];
          });
        }
        
      } else {
        print('❌ Seepays: Failed to load transaction history: ${response.statusCode}');
        print('Response: ${response.body}');
        
        // Tampilkan pesan error
        setState(() {
          recentTransactions = [TransactionHistoryModel(tujuan: 'Belum pernah transaksi di produk ini')];
        });
      }
      // ================================================================================
      
    } catch (e) {
      print('Error loading transaction history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          Alert(
            'Gagal memuat riwayat transaksi',
            isError: true,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loadingHistory = false;
        });
      }
    }
  }

  // Get product logo from API response
  String _getProductLogo(TransactionHistoryModel trx) {
    // Cek apakah ada logo produk dari kategori sesuai struktur API response
    if (trx.produkId != null && 
        trx.produkId.kategoriId != null && 
        trx.produkId.kategoriId.urlImage != null &&
        trx.produkId.kategoriId.urlImage.isNotEmpty) {
      return trx.produkId.kategoriId.urlImage;
    }
    // Return empty string jika tidak ada logo
    return '';
  }

  // Filter produk pulsa yang lebih fleksibel
  bool _isPulsaProduct(TransactionHistoryModel trx) {
    print('🔍 Debugging filter for transaction: ${trx.produkId?.name}');
    
    // Cek nama produk mengandung kata yang berhubungan dengan pulsa (case insensitive)
    if (trx.produkId != null && trx.produkId.name != null) {
      String productName = trx.produkId.name.toLowerCase();
      print('📱 Product name: $productName');
      
      // Filter yang lebih fleksibel untuk pulsa
      bool isPulsa = productName.contains('pulsa') || 
                     productName.contains('telkomsel') ||
                     productName.contains('indosat') ||
                     productName.contains('xl') ||
                     productName.contains('three') ||
                     productName.contains('smartfren') ||
                     productName.contains('axis') ||
                     productName.contains('tsel') ||
                     productName.contains('simpati') ||
                     productName.contains('as') ||
                     productName.contains('matrix') ||
                     productName.contains('mentari');
      
      print('✅ Is pulsa product: $isPulsa');
      return isPulsa;
    }
    
    // Fallback: cek keterangan transaksi
    if (trx.keterangan != null && trx.keterangan.isNotEmpty) {
      String keterangan = trx.keterangan.toLowerCase();
      print('📝 Keterangan: $keterangan');
      
      bool isPulsaKeterangan = keterangan.contains('pulsa') ||
                               keterangan.contains('telkomsel') ||
                               keterangan.contains('indosat') ||
                               keterangan.contains('xl') ||
                               keterangan.contains('three') ||
                               keterangan.contains('smartfren') ||
                               keterangan.contains('axis') ||
                               keterangan.contains('tsel') ||
                               keterangan.contains('simpati') ||
                               keterangan.contains('as') ||
                               keterangan.contains('matrix') ||
                               keterangan.contains('mentari');
      
      print('✅ Is pulsa keterangan: $isPulsaKeterangan');
      return isPulsaKeterangan;
    }
    
    // Fallback: cek type produk (type 2 = PPOB/Pulsa)
    bool isTypePulsa = trx.produkId != null && trx.produkId.type == 2;
    print('🔢 Type check (type 2): $isTypePulsa');
    
    return isTypePulsa;
  }

  // Load hardcoded data sebagai fallback
  void _loadHardcodedPulsaData() {
    List<Map<String, dynamic>> hardcodedData = [
      {
        '_id': '1',
        'status': 2, // Success
        'admin': 0,
        'counter': 1,
        'tujuan': '081234567890',
        'produk_id': {
          '_id': 'prod1',
          'name': 'Pulsa Telkomsel Reguler',
          'type': 2, // Pulsa/PPOB
          'icon': 'https://ayoba.co.id/dokumen/provider/tsel.png',
          'category': 'pulsa',
        },
        'harga_jual': 25000,
        'sn': 'SN001',
        'payment_by': 'saldo',
        'payment_id': 'PAY001',
        'created_at': '2024-01-15T10:30:00Z',
        'updated_at': '2024-01-15T10:35:00Z',
        'keterangan': 'Pulsa Telkomsel Reguler denom 25Ribu',
        'poin': 25,
        'print': [],
      },
      {
        '_id': '2',
        'status': 2, // Success
        'admin': 0,
        'counter': 1,
        'tujuan': '085678901234',
        'produk_id': {
          '_id': 'prod2',
          'name': 'Pulsa Indosat Reguler',
          'type': 2, // Pulsa/PPOB
          'icon': 'https://ayoba.co.id/dokumen/provider/indosat.png',
          'category': 'pulsa',
        },
        'harga_jual': 20000,
        'sn': 'SN002',
        'payment_by': 'saldo',
        'payment_id': 'PAY002',
        'created_at': '2024-01-14T15:20:00Z',
        'updated_at': '2024-01-14T15:25:00Z',
        'keterangan': 'Pulsa Indosat Reguler denom 20Ribu',
        'poin': 20,
        'print': [],
      },
    ];

    // Convert hardcoded data to TransactionHistoryModel
    List<TransactionHistoryModel> hardcodedHistory = hardcodedData
        .map((json) => TransactionHistoryModel.fromJson(json))
        .toList();
    
    setState(() {
      transactionHistory = hardcodedHistory;
      recentTransactions = hardcodedHistory;
    });
    
    print('Loaded ${recentTransactions.length} hardcoded pulsa transactions as fallback');
  }

  // Dapatkan statistik filter pulsa
  Map<String, dynamic> _getPulsaFilterStats() {
    if (transactionHistory.isEmpty) {
      return {
        'total_transactions': 0,
        'pulsa_transactions': 0,
        'filter_percentage': 0.0,
        'providers': [],
      };
    }

    int totalTransactions = transactionHistory.length;
    int pulsaTransactions = recentTransactions.length;
    double filterPercentage = (pulsaTransactions / totalTransactions) * 100;
    
    // Dapatkan provider unik dari transaksi pulsa
    Set<String> providers = recentTransactions
        .where((trx) => trx.produkId != null && trx.produkId.name != null)
        .map((trx) => trx.produkId.name)
        .toSet();

    return {
      'total_transactions': totalTransactions,
      'pulsa_transactions': pulsaTransactions,
      'filter_percentage': filterPercentage,
      'providers': providers.toList(),
    };
  }

  // Get operator icon based on phone number prefix
  String getOperatorIcon(String phoneNumber) {
    if (phoneNumber.startsWith('0814') || phoneNumber.startsWith('0815') || 
        phoneNumber.startsWith('0816') || phoneNumber.startsWith('0855') || 
        phoneNumber.startsWith('0856') || phoneNumber.startsWith('0857') || 
        phoneNumber.startsWith('0858')) {
      return 'https://ayoba.co.id/dokumen/provider/indosat.png';
    } else if (phoneNumber.startsWith('0811') || phoneNumber.startsWith('0812') || 
               phoneNumber.startsWith('0813') || phoneNumber.startsWith('0821') || 
               phoneNumber.startsWith('0822') || phoneNumber.startsWith('0823') || 
               phoneNumber.startsWith('0852') || phoneNumber.startsWith('0853') || 
               phoneNumber.startsWith('0851')) {
      return 'https://ayoba.co.id/dokumen/provider/tsel.png';
    } else if (phoneNumber.startsWith('0895') || phoneNumber.startsWith('0896') || 
               phoneNumber.startsWith('0897') || phoneNumber.startsWith('0898') || 
               phoneNumber.startsWith('0899')) {
      return 'https://ayoba.co.id/dokumen/provider/three.png';
    } else if (phoneNumber.startsWith('0817') || phoneNumber.startsWith('0818') || 
               phoneNumber.startsWith('0819') || phoneNumber.startsWith('0859') || 
               phoneNumber.startsWith('0877') || phoneNumber.startsWith('0878')) {
      return 'https://ayoba.co.id/dokumen/provider/xl.png';
    } else if (phoneNumber.startsWith('0881') || phoneNumber.startsWith('0882') || 
               phoneNumber.startsWith('0883') || phoneNumber.startsWith('0884') || 
               phoneNumber.startsWith('0885') || phoneNumber.startsWith('0886') || 
               phoneNumber.startsWith('0887') || phoneNumber.startsWith('0888') || 
               phoneNumber.startsWith('0889')) {
      return 'https://ayoba.co.id/dokumen/provider/smart.png';
    } else if (phoneNumber.startsWith('0838') || phoneNumber.startsWith('0831') || 
               phoneNumber.startsWith('0832') || phoneNumber.startsWith('0833')) {
      return 'https://ayoba.co.id/dokumen/provider/axis.png';
    }
    return '';
  }

  // Mask phone number for display without using 'X'
  String maskPhoneNumber(String phoneNumber) {
    if (phoneNumber == null) return '';
    if (phoneNumber.length <= 6) return phoneNumber;
    final String start = phoneNumber.substring(0, 6);
    final String end = phoneNumber.substring(phoneNumber.length - 2);
    final int hiddenCount = phoneNumber.length - 6;
    final String hidden = List.filled(hiddenCount, 'X').join();
    return '$start$hidden$end';
  }

  // Select number from recent transactions
  void selectRecentNumber(String phoneNumber) {
    setState(() {
      nomorHp.text = phoneNumber;
    });
    
    // Auto-trigger denom search if it's a valid number
    if (phoneNumber.length >= 4 && phoneNumber.startsWith('08')) {
      if (phoneNumber.substring(0, 4) != prefixNomor) {
        setState(() {
          listDenom.clear();
          prefixNomor = phoneNumber.substring(0, 4);
          loading = true;
        });
        getDenom(phoneNumber);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // List<String> pkgListActivateContact = [
    // 'id.payuni.mobile',
    // 'com.tapayment.mobile',
    // 'id.popay.app',
    // 'id.ndmmobile.apk',
    // 'com.staypay.app',
    // 'id.bisabayar.app',
    // 'com.phoenixpayment.app',
    // 'com.kingreloads.app',
    // 'com.mopay.mobile',
    // 'id.funmo.mobile',
    // 'id.yukpay.mobile',
    // 'id.pmpay.mobile',
    // 'id.paymobileku.app',
    // 'com.passpay.agenpulsamurah',
    // 'id.warungpayid.mobile',
    // 'ayoba.co.id',
    // 'com.ptspayment.mobile',
    // 'id.esaldoku.mobile',
    // 'id.akupay.mobile',
    // 'id.wallpayku.apk',
    // ];

    // pkgListActivateContact.forEach((element) {
    //   if (element == packageName) {
    //     activateContact = true;
    //   }
    // });

    List<String> pkgNameLogoAppCoverList = [
      'com.eazyin.mobile',
    ];

    pkgNameLogoAppCoverList.forEach((e) {
      if (e == packageName) logoAppCover = true;
    });

    List<Map<String, dynamic>> operatorTelp = [
      {
        'name': 'indosat',
        'prefix': '0814, 0815, 0816, 0855, 0856, 0857, 0858',
        'url': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/12/Indosat_Ooredoo.svg/2560px-Indosat_Ooredoo.svg.png',
      },
      {
        'name': 'telkomsel',
        'prefix': '0811, 0812, 0813, 0821, 0822, 0823, 0852, 0853, 0851',
        'url': 'https://maxsi.id/web/assets/logo-telkomsel-baru.DYhv_uL8_1T5nit.webp',
      },
      {
        'name': 'three',
        'prefix': '0895, 0896, 0897, 0898, 0899',
        'url': 'http://bloguna.com/wp-content/uploads/2025/06/Logo-3-Tri-Three-Format-PNG-PDF-AI-SVG-EPS-CDR.webp',
      },
      {
        'name': 'xl',
        'prefix': '0817, 0818, 0819, 0859, 0877, 0878',
        'url': 'https://staticxl.ext.xlaxiata.co.id/s3fs-public/media/images/big-xl-logo.png',
      },
      {
        'name': 'smartfren',
        'prefix': '0881, 0882, 0883, 0884, 0885, 0886, 0887, 0888, 0889',
        'url': 'https://www.logo.wine/a/logo/Smartfren/Smartfren-Logo.wine.svg',
      },
      {
        'name': 'axis',
        'prefix': '0838, 0831, 0832, 0833',
        'url':
            // 'https://i.pinimg.com/originals/d0/31/31/d031314a78e8ac9d4b4ce2593698ee1f.png',
            'https://download.logo.wine/logo/Axis_Telecom/Axis_Telecom-Logo.wine.png',
      },
    ];

    List<String> pkgNameLogoMenuCoverList = [
      'ayoba.co.id',
      'com.eralink.mobileapk',
      'mobile.payuni.id',
      'id.paymobileku.app',
      'popay.id',
      'com.popayfdn',
      'com.xenaja.app',
      'com.talentapay.android',
      'com.seepays.mobile',
      'com.seepaysbiller.app',
    ];

    List<String> pkgNameIconMenuList = [
      'id.outletpay.mobile',
    ];

    var regex = new RegExp("\\b(?:$prefixNomor)\\b", caseSensitive: false);
    var find =
        operatorTelp.where((element) => regex.hasMatch(element['prefix']));

    if (find.isNotEmpty) {
      find.forEach((element) => operatorIcon = element['url']);
    } else {
      operatorIcon = '';
    }

    Widget operatorHeaderIcon() {
      if (operatorIcon.isNotEmpty) {
        return Container(
          padding: EdgeInsets.all(40),
          child: CachedNetworkImage(
            imageUrl: operatorIcon,
            height: 10,
            placeholder: (context, url) => SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            errorWidget: (context, url, error) => Icon(
              Icons.network_check,
              color: Colors.white,
              size: 28,
            ),
          ),
        );
      } else {
        return SizedBox();
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.menuModel.name),
        centerTitle: true,
        elevation: 0,
        backgroundColor: packageName == 'com.lariz.mobile'
            ? Theme.of(context).secondaryHeaderColor
            : Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.home_rounded),
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) =>
                      configAppBloc.layoutApp?.valueWrapper?.value['home'] ??
                      templateConfig[
                          configAppBloc.templateCode.valueWrapper?.value],
                ),
                (route) => false),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
        ),
        child: Stack(
          children: <Widget>[
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.white,
            ),
            Column(
              children: <Widget>[
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * .2,
                  decoration: BoxDecoration(
                    color: packageName == 'com.lariz.mobile'
                        ? Theme.of(context).secondaryHeaderColor
                        : const Color(0xFFA259FF),
                  ),
                  child: logoAppCover
                      ? Center(
                          child: CachedNetworkImage(
                            imageUrl: configAppBloc
                                .iconApp.valueWrapper?.value['logoLogin'],
                            width: MediaQuery.of(context).size.width * .4,
                            placeholder: (context, url) => SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.image_not_supported,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        )
                      : logoProductMenuCover
                          ? operatorHeaderIcon()
                          : null,
                ),
                Container(
                    padding: EdgeInsets.all(20),
                    child: packageName == 'com.eralink.mobileapk'
                        ? TextFormField(
                            // TextFormField untuk Eralink
                            controller: nomorHp,
                            keyboardType: TextInputType.number,
                            cursorColor: Theme.of(context).primaryColor,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor)),
                              focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor)),
                              isDense: true,
                              labelText: 'Nomor Tujuan',
                              labelStyle: TextStyle(
                                  color:
                                      Theme.of(context).secondaryHeaderColor),
                              prefixIcon: InkWell(
                                  child: Icon(
                                    Icons.cached,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  onTap: () async {
                                    FavoriteNumberModel response =
                                        await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            FavoriteNumber('prepaid'),
                                      ),
                                    );

                                    print(
                                        'response favorite-number -> $response');
                                    if (response == null) return;
                                    setState(() {
                                      nomorHp.text = response.tujuan;
                                    });

                                    if (response.tujuan.length >= 4 &&
                                        response.tujuan.startsWith('08')) {
                                      if (response.tujuan.substring(0, 4) !=
                                          prefixNomor) {
                                        setState(() {
                                          listDenom.clear();
                                          prefixNomor =
                                              response.tujuan.substring(0, 4);
                                          loading = true;
                                          pkgNameLogoMenuCoverList.forEach((e) {
                                            if (e == packageName)
                                              logoProductMenuCover = true;
                                          });
                                        });
                                        _handleNumberInput(response.tujuan);
                                      }
                                    }
                                  }),
                              suffixIcon: InkWell(
                                child: Icon(
                                  Icons.contacts,
                                  color: Theme.of(context).primaryColor,
                                ),
                                onTap: () {
                                  Navigator.of(context)
                                      .push(MaterialPageRoute(
                                          builder: (_) => ContactPage()))
                                      .then((nomor) {
                                    if (nomor != null) {
                                      nomorHp.text = nomor;
                                      _handleNumberInput(nomor);
                                    }
                                  });
                                },
                              ),
                            ),
                            style: TextStyle(
                              fontWeight: configAppBloc
                                      .boldNomorTujuan.valueWrapper.value
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            onChanged: (str) {
                              _handleNumberInput(str);
                            },
                          )
                        : TextFormField(
                            // TextFormField untuk produk lain (non-Eralink)
                            controller: nomorHp,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                              labelText: 'Nomor Tujuan',
                              prefixIcon: InkWell(
                                  child: Icon(Icons.cached),
                                  onTap: () async {
                                    FavoriteNumberModel response =
                                        await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            FavoriteNumber('prepaid'),
                                      ),
                                    );

                                    print(
                                        'response favorite-number -> $response');
                                    if (response == null) return;
                                    setState(() {
                                      nomorHp.text = response.tujuan;
                                    });

                                    if (response.tujuan.length >= 4 &&
                                        response.tujuan.startsWith('08')) {
                                      if (response.tujuan.substring(0, 4) !=
                                          prefixNomor) {
                                        setState(() {
                                          listDenom.clear();
                                          prefixNomor =
                                              response.tujuan.substring(0, 4);
                                          loading = true;
                                          pkgNameLogoMenuCoverList.forEach((e) {
                                            if (e == packageName)
                                              logoProductMenuCover = true;
                                          });
                                        });
                                        _handleNumberInput(response.tujuan);
                                      }
                                    }
                                  }),
                              suffixIcon: InkWell(
                                child: Icon(Icons.contacts),
                                onTap: () {
                                  Navigator.of(context)
                                      .push(MaterialPageRoute(
                                          builder: (_) => ContactPage()))
                                      .then((nomor) {
                                    if (nomor != null) {
                                      nomorHp.text = nomor;
                                      _handleNumberInput(nomor);
                                    }
                                  });
                                },
                              ),
                            ),
                            style: TextStyle(
                              fontWeight: configAppBloc
                                      .boldNomorTujuan.valueWrapper.value
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            onChanged: (str) {
                              _handleNumberInput(str);
                            },
                          )),
                
                // Transaksi Terakhir Section - Design PLN Style
                if (loadingHistory)
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Memuat riwayat transaksi...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  )
                // FITUR SUGGEST HISTORY NOMOR PEMBELI - EKSKLUSIF UNTUK APLIKASI SEEPAYS
                else if (recentTransactions.isNotEmpty && packageName == 'com.seepaysbiller.app')
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 2),
                        
                        // Loading State
                        loadingHistory
                            ? Container(
                                width: double.infinity,
                                height: 40,
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Loading History . . . ...',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                height: 40,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: recentTransactions.length,
                                  itemBuilder: (context, index) {
                                    final trx = recentTransactions[index];
                                    return Container(
                                      margin: EdgeInsets.only(right: 8),
                                      child: trx.tujuan == 'Belum pernah transaksi di produk ini'
                                        ? Container(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              trx.tujuan,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          )
                                        : ActionChip(
                                            label: Text(
                                              trx.tujuan,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            backgroundColor: Colors.blue[50],
                                            labelStyle: TextStyle(color: Colors.blue[700]),
                                            onPressed: () {
                                              nomorHp.text = trx.tujuan;
                                              // Trigger getDenom jika nomor valid
                                              if (trx.tujuan.length >= 4 && trx.tujuan.startsWith('08')) {
                                                _handleNumberInput(trx.tujuan);
                                              }
                                            },
                                          ),
                                    );
                                  },
                                ),
                              ),
                      ],
                    ),
                  ),
                

                
                // Info text
                // if (recentTransactions.isNotEmpty)
                //   // Container(
                //   //   margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                //   //   padding: EdgeInsets.all(10),
                //   //   decoration: BoxDecoration(
                //   //     color: Theme.of(context).primaryColor.withOpacity(0.1),
                //   //     borderRadius: BorderRadius.circular(8),
                //   //   ),
                //   //   // child: Row(
                //   //   //   children: [
                //   //   //     Icon(
                //   //   //       Icons.info_outline,
                //   //   //       color: Theme.of(context).primaryColor,
                //   //   //       size: 20,
                //   //   //     ),
                //   //   //     SizedBox(width: 8),
                //   //   //     // Expanded(
                //   //   //     //   child: Text(
                //   //   //     //     'Contoh Nomor yang pernah transaksi',
                //   //   //     //     style: TextStyle(
                //   //   //     //       fontSize: 12,
                //   //   //     //       color: Theme.of(context).primaryColor,
                //   //   //     //       fontStyle: FontStyle.italic,
                //   //   //     //     ),
                //   //   //     //   ),
                //   //   //     // ),
                //   //   //   ],
                //   //   // ),
                //   // )
                // else if (!loadingHistory)
                //   Container(
                //     margin: EdgeInsets.symmetric(horizontal: 20),
                //     padding: EdgeInsets.all(15),
                //     decoration: BoxDecoration(
                //       border: Border.all(color: Colors.grey.shade300, width: 1),
                //       borderRadius: BorderRadius.circular(10),
                //     ),
                //     child: Row(
                //       children: [
                //         Icon(
                //           Icons.info_outline,
                //           color: Colors.grey.shade600,
                //           size: 20,
                //         ),
                //         SizedBox(width: 10),
                //         Expanded(
                //           child: Text(
                //             'Belum ada transaksi pulsa sebelumnya',
                //             style: TextStyle(
                //               fontSize: 14,
                //               color: Colors.grey.shade600,
                //               fontStyle: FontStyle.italic,
                //             ),
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),
                
                loading
                    ? Expanded(
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          child: Center(
                            child: SpinKitThreeBounce(
                                color: packageName == 'com.lariz.mobile'
                                    ? Theme.of(context).secondaryHeaderColor
                                    : Theme.of(context).primaryColor,
                                size: 35),
                          ),
                        ),
                      )
                    : Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.all(20),
                          itemCount: max(0, listDenom?.length * 2 - 1 ?? 0),
                          itemBuilder: (ctx, i) {
                            if (i.isOdd) {
                              return SizedBox(height: 10);
                            }
                            int actualIndex = i ~/ 2;
                            PulsaModel denom = listDenom[actualIndex];
                            Color boxColor = selectedDenom != null
                                ? selectedDenom.id == denom.id
                                    ? packageName == 'com.lariz.mobile'
                                        ? Theme.of(context)
                                            .secondaryHeaderColor
                                            .withOpacity(.8)
                                        : Theme.of(context)
                                            .primaryColor
                                            .withOpacity(.8)
                                    : Colors.white
                                : Colors.white;
                            Color textColor = selectedDenom != null
                                ? selectedDenom.id == denom.id
                                    ? Colors.white
                                    : Colors.grey.shade700
                                : Colors.grey.shade700;
                            Color priceColor = selectedDenom != null
                                ? selectedDenom.id == denom.id
                                    ? Colors.white
                                    : Colors.green
                                : Colors.green;
                            return InkWell(
                              onTap: () => selectDenom(denom),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                    color: boxColor,
                                    borderRadius: BorderRadius.circular(10.0),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black.withOpacity(.1),
                                          offset: Offset(5, 10.0),
                                          blurRadius: 20)
                                    ]),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    foregroundColor: packageName ==
                                            'com.lariz.mobile'
                                        ? Theme.of(context).secondaryHeaderColor
                                        : Theme.of(context).primaryColor,
                                    backgroundColor: selectedDenom != null
                                        ? selectedDenom.id == denom.id
                                            ? Colors.white
                                            : packageName == 'com.lariz.mobile'
                                                ? Theme.of(context)
                                                    .secondaryHeaderColor
                                                    .withOpacity(.1)
                                                : Theme.of(context)
                                                    .primaryColor
                                                    .withOpacity(.1)
                                        : packageName == 'com.lariz.mobile'
                                            ? Theme.of(context)
                                                .secondaryHeaderColor
                                                .withOpacity(.1)
                                            : Theme.of(context)
                                                .primaryColor
                                                .withOpacity(.1),
                                    child: Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: CachedNetworkImage(
                                        imageUrl: pkgNameIconMenuList
                                                .contains(packageName)
                                            ? operatorIcon
                                            : (denom.category
                                                        is KategoriPulsaModel &&
                                                    denom.category.iconUrl !=
                                                        null)
                                                ? denom.category.iconUrl
                                                : widget.menuModel.icon,
                                        placeholder: (context, url) => SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                        errorWidget: (context, url, error) => Icon(
                                          Icons.image,
                                          size: 18,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    denom.nama,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  subtitle: Text(denom.desc ?? '',
                                      style: TextStyle(
                                          fontSize: 10, color: textColor)),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: denom.hargaPromo == null
                                        ? <Widget>[
                                            Text(
                                              formatRupiah(denom.hargaJual),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: priceColor,
                                              ),
                                            ),
                                            SizedBox(
                                              height: !configAppBloc
                                                      .displayGangguan
                                                      .valueWrapper
                                                      .value
                                                  ? 0
                                                  : denom.note.isEmpty
                                                      ? 0
                                                      : 5,
                                            ),
                                            !configAppBloc.displayGangguan
                                                    .valueWrapper.value
                                                ? SizedBox()
                                                : denom.note.isEmpty
                                                    ? SizedBox()
                                                    : Container(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                          vertical: 3,
                                                          horizontal: 5,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: denom.note ==
                                                                  'gangguan'
                                                              ? Colors
                                                                  .red.shade800
                                                              : denom.note ==
                                                                      'lambat'
                                                                  ? Colors.amber
                                                                      .shade800
                                                                  : Colors.green
                                                                      .shade800,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5),
                                                        ),
                                                        child: Text(
                                                          denom.note
                                                              .toUpperCase(),
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                          ]
                                        : <Widget>[
                                            Text(
                                              formatRupiah(denom.hargaPromo),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: priceColor,
                                              ),
                                            ),
                                            SizedBox(height: 3),
                                            Text(
                                              formatRupiah(denom.hargaJual),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Colors.grey,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                            ),
                                            SizedBox(
                                              height: !configAppBloc
                                                      .displayGangguan
                                                      .valueWrapper
                                                      .value
                                                  ? 0
                                                  : denom.note.isEmpty
                                                      ? 0
                                                      : 3,
                                            ),
                                            !configAppBloc.displayGangguan
                                                    .valueWrapper.value
                                                ? SizedBox()
                                                : denom.note.isEmpty
                                                    ? SizedBox()
                                                    : Container(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                          vertical: 3,
                                                          horizontal: 5,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: denom.note ==
                                                                  'gangguan'
                                                              ? Colors
                                                                  .red.shade800
                                                              : denom.note ==
                                                                      'lambat'
                                                                  ? Colors.amber
                                                                      .shade800
                                                                  : Colors.green
                                                                      .shade800,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(5),
                                                        ),
                                                        child: Text(
                                                          denom.note
                                                              .toUpperCase(),
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                          ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: selectedDenom == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: packageName == 'com.lariz.mobile'
                  ? Theme.of(context).secondaryHeaderColor
                  : Theme.of(context).primaryColor,
              foregroundColor:
                  Theme.of(context).floatingActionButtonTheme.foregroundColor,
              icon: Icon(Icons.navigate_next),
              label: Text('Beli'),
              onPressed: () {
                if (nomorHp.text.length > 3) {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => InquiryPrepaid(
                          selectedDenom.kodeProduk, nomorHp.text)));
                }
              },
            ),
    );
  }
}

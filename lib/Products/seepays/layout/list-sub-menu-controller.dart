// @dart=2.9

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile/models/menu.dart';
import 'package:mobile/provider/analitycs.dart';
import 'package:mobile/screen/detail-denom-postpaid/detail-postpaid.dart';
import 'package:mobile/screen/detail-denom/detail-denom.dart';
import 'package:mobile/Products/seepays/layout/detail-denom.dart';
import 'package:mobile/Products/seepays/layout/detail-denom-postpaid.dart';
import 'package:mobile/screen/dynamic-prepaid/dynamic-denom.dart';
import 'package:mobile/Products/seepays/layout/list-sub-menu.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/bloc/Bloc.dart' show bloc;
import 'package:mobile/bloc/Api.dart' show apiUrl;

// Global cache untuk submenu
Map<String, List<MenuModel>> _globalSubmenuCache = {};

abstract class ListSubMenuController extends State<ListSubMenu>
    with TickerProviderStateMixin {
  bool loading = false; // Mulai tanpa loading untuk submenu pascabayar
  MenuModel currentMenu;
  List<MenuModel> listMenu = [];
  List<MenuModel> tempMenu = [];
  TextEditingController query = TextEditingController();

  bool isProductIconMenu = false;
  bool _showEmptyState = false; // Flag untuk menampilkan empty state setelah timeout
  
  // Getter untuk akses dari UI
  bool get showEmptyState => _showEmptyState;

  @override
  void initState() {
    super.initState();
    currentMenu = widget.menuModel;
    
    // Debug: Trace sumber menu ID
    print('🔍 ListSubMenu Debug: Menu ID yang digunakan: ${currentMenu.id}');
    print('🔍 ListSubMenu Debug: Menu Name: ${currentMenu.name}');
    print('🔍 ListSubMenu Debug: Menu Type: ${currentMenu.type}');
    print('🔍 ListSubMenu Debug: Menu Jenis: ${currentMenu.jenis}');
    print('🔍 ListSubMenu Debug: Menu Category ID: ${currentMenu.category_id}');
    print('🔍 ListSubMenu Debug: Menu Kode Produk: ${currentMenu.kodeProduk}');
    
    analitycs.pageView('/menu/' + currentMenu.id, {
      'userId': bloc.userId.valueWrapper?.value,
      'title': 'Buka Menu ' + currentMenu.name
    });
    // Immediate fetch tanpa delay dari menu utama
    _getDataImmediate();
  }

  // Method untuk immediate fetch submenu menggunakan cache atau API
  _getDataImmediate() async {
    print('🚀 ListSubMenu: Starting immediate fetch for submenu');
    // Hilangkan loading state untuk submenu pascabayar
    // setState(() {
    //   loading = true;
    // });

    // Cek cache terlebih dahulu
    List<MenuModel> cachedSubmenu = _globalSubmenuCache[currentMenu.id] ?? [];
    
    if (cachedSubmenu.isNotEmpty) {
      print('⚡ ListSubMenu: Using cached submenu (${cachedSubmenu.length} items)');
      
      for (MenuModel menu in cachedSubmenu) {
        print('📋 Sub-menu Cached: ${menu.name} | type: ${menu.type} | category_id: "${menu.category_id}" | kodeProduk: "${menu.kodeProduk}"');
      }
      
      tempMenu = cachedSubmenu;
      listMenu = cachedSubmenu;
      
      setState(() {
        loading = false; // Langsung set ke false tanpa menampilkan loading
      });
      
      print('✅ ListSubMenu: Immediate fetch from cache completed');
      return;
    }
    
    // Jika tidak ada cache, fetch dari API secara background tanpa loading
    print('🌐 ListSubMenu: Cache not found, fetching from API in background');
    String apiEndpoint = '$apiUrl/menu/${currentMenu.id}/child';
    print('🌐 ListSubMenu Immediate API Endpoint: $apiEndpoint');
    
    // Set loading ke false dulu untuk menampilkan UI kosong
    setState(() {
      loading = false;
      listMenu = []; // Tampilkan menu kosong dulu
      _showEmptyState = false; // Reset empty state
    });
    
    // Timeout 5 detik untuk menampilkan empty state jika tidak ada data
    Future.delayed(Duration(seconds: 10), () {
      if (mounted && listMenu.isEmpty) {
        print('⏰ ListSubMenu: Timeout 5 detik tercapai, menampilkan empty state');
        setState(() {
          _showEmptyState = true;
        });
        // Baru sekarang show snackbar setelah timeout
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Produk Masih Kosong'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
    
    try {
      http.Response response = await http.get(
          Uri.parse(apiEndpoint),
          headers: {'Authorization': bloc.token.valueWrapper?.value});

      print('📡 ListSubMenu Background Response Status: ${response.statusCode}');
      print('📡 ListSubMenu Background Response Body: ${response.body}');

      if (response.statusCode == 200) {
        List<MenuModel> lm = (jsonDecode(response.body)['data'] as List)
            .map((m) => MenuModel.fromJson(m))
            .toList();
        
        print('📊 ListSubMenu Background: ${lm.length} sub-menu items found');
        for (MenuModel menu in lm) {
          print('📋 Sub-menu Background: ${menu.name} | type: ${menu.type} | category_id: "${menu.category_id}" | kodeProduk: "${menu.kodeProduk}"');
        }
        
        // Cache hasil untuk penggunaan selanjutnya
        _globalSubmenuCache[currentMenu.id] = lm;
        
        // Check if empty - tapi jangan langsung kasih pesan, tunggu timeout dulu
        if (lm.isEmpty) {
          print('📭 ListSubMenu: Submenu kosong dari API, tapi tunggu timeout 5 detik dulu');
          setState(() {
            listMenu = [];
            tempMenu = [];
          });
          // Jangan langsung show snackbar, tunggu timeout dulu
        } else {
          // Update UI dengan data yang baru
          setState(() {
            tempMenu = lm;
            listMenu = lm;
          });
        }
      } else {
        print('❌ ListSubMenu Background: Failed to load submenu: ${response.statusCode}');
        setState(() {
          listMenu = [];
        });
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memuat data produk'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ ListSubMenu Background: Error loading submenu: $e');
      setState(() {
        listMenu = [];
      });
    }
    
    print('✅ ListSubMenu: Background fetch completed');
  }

  getData() async {
    setState(() {
      loading = true;
    });

    String apiEndpoint = '$apiUrl/menu/${currentMenu.id}/child';
    print('🌐 ListSubMenu API Endpoint: $apiEndpoint');
    
    http.Response response = await http.get(
        Uri.parse(apiEndpoint),
        headers: {'Authorization': bloc.token.valueWrapper?.value});

    print('📡 ListSubMenu Response Status: ${response.statusCode}');
    print('📡 ListSubMenu Response Body: ${response.body}');

    if (response.statusCode == 200) {
      List<MenuModel> lm = (jsonDecode(response.body)['data'] as List)
          .map((m) => MenuModel.fromJson(m))
          .toList();
      
      print('📊 ListSubMenu: ${lm.length} sub-menu items found');
      for (MenuModel menu in lm) {
        print('📋 Sub-menu: ${menu.name} | type: ${menu.type} | category_id: "${menu.category_id}" | kodeProduk: "${menu.kodeProduk}"');
      }
      
      tempMenu = lm;
      listMenu = lm;
    } else {
      listMenu = [];
    }

    setState(() {
      loading = false;
    });
  }

  onTapMenu(MenuModel menu) async {
    print('📌 ListSubMenu Menu diklik: ${menu.name} | type: ${menu.type} | category_id: "${menu.category_id}" | kodeProduk: "${menu.kodeProduk}"');
    
    if (menu.category_id.isNotEmpty && menu.type == 1) {
      print('➡️ ListSubMenu menuju ke: SeepaysDetailDenom (Prepaid)');
      return Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SeepaysDetailDenom(menu),
        ),
      );
    } else if (menu.kodeProduk.isNotEmpty && menu.type == 2) {
      print('➡️ ListSubMenu menuju ke: SeepaysDetailDenomPostpaid (Postpaid)');
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => SeepaysDetailDenomPostpaid(menu)));
    } else if (menu.category_id.isEmpty) {
      if (menu.type == 3) {
        print('➡️ ListSubMenu menuju ke: DynamicPrepaidDenom');
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => DynamicPrepaidDenom(menu)));
      } else {
        print('➡️ ListSubMenu menuju ke: ListSubMenu (nested)');
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => ListSubMenu(menu)));
      }
    } else {
      print('❌ ListSubMenu: Menu tidak memenuhi kondisi routing apapun');
    }
  }
} 
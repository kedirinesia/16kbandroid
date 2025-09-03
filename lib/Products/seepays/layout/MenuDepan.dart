// @dart=2.9

import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_page_transition/flutter_page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:mobile/models/menu.dart';
import '../../../component/menudepan-loading.dart';
import '../../../config.dart';
import '../../seepays/layout/morepage.dart';

import 'package:mobile/screen/detail-denom-postpaid/detail-postpaid.dart';

// Import untuk external access
// import 'package:mobile/Products/seepays/layout/list-sub-menu-controller.dart';
import 'package:mobile/screen/detail-denom/detail-denom.dart';
import 'package:mobile/screen/dynamic-prepaid/dynamic-denom.dart';
 
import 'package:mobile/screen/list-grid-menu/list-grid-menu.dart';
import 'list-sub-menu.dart';
import 'pulsa.dart';
import 'package:mobile/screen/transaksi/voucher_bulk.dart';

class MenuDepan extends StatefulWidget {
  final int grid;
  final List<MenuModel> menus;
  final int baris;
  final gradient;
  final double radius;

  MenuDepan({
    @required this.grid,
    this.menus,
    this.gradient,
    this.baris,
    this.radius,
  });

  @override
  _MenuDepanState createState() => _MenuDepanState();
}

class _MenuDepanState extends State<MenuDepan> {
  bool loading = true;
  bool failed = false;
  List<MenuModel> _prabayarMenu = [];
  List<MenuModel> _pascabayarMenu = [];
  List<MenuModel> _prabayarMoreMenu = [];
  List<MenuModel> _pascabayarMoreMenu = [];
  List<MenuModel> _moreMenu = [];

  @override
  void initState() {
    super.initState();
    if (widget.menus == null) {
      getMenu();
    } else {
      _splitMenusByCategory(widget.menus);
      loading = false;
    }
  }

  // Cache untuk menyimpan data menu
  static List<MenuModel> _cachedMenuData = [];
  static bool _isDataLoaded = false;
  
  // Method untuk clear cache dan force reload
  static void clearCache() {
    _cachedMenuData.clear();
    _isDataLoaded = false;
    _cachedPrabayarMenu.clear();
    _cachedPascabayarMenu.clear();
    _cachedPrabayarMoreMenu.clear();
    _cachedPascabayarMoreMenu.clear();
    _cachedMoreMenu.clear();
    _cachedSubmenus.clear();
    print('🧹 MenuDepan: Cache cleared, akan fetch data fresh dari server');
  }
  
  // Cache untuk menyimpan hasil pemisahan kategori
  static List<MenuModel> _cachedPrabayarMenu = [];
  static List<MenuModel> _cachedPascabayarMenu = [];
  static List<MenuModel> _cachedPrabayarMoreMenu = [];
  static List<MenuModel> _cachedPascabayarMoreMenu = [];
  static List<MenuModel> _cachedMoreMenu = [];
  
  // Cache untuk submenu yang sudah di-preload
  static Map<String, List<MenuModel>> _cachedSubmenus = {};

  Future<void> getMenu() async {
    try {
      // TEMPORARY: Force refresh untuk debug data mismatch issue
      // Comment baris ini setelah masalah resolved
      // clearCache();
      
      // Gunakan cache jika sudah ada data
      if (_isDataLoaded && _cachedMenuData.isNotEmpty) {
        print('📊 Using cached menu data: ${_cachedMenuData.length} items');
        // Gunakan hasil cache yang sudah dipisahkan
        _prabayarMenu = List<MenuModel>.from(_cachedPrabayarMenu);
        _pascabayarMenu = List<MenuModel>.from(_cachedPascabayarMenu);
        _prabayarMoreMenu = List<MenuModel>.from(_cachedPrabayarMoreMenu);
        _pascabayarMoreMenu = List<MenuModel>.from(_cachedPascabayarMoreMenu);
        _moreMenu = List<MenuModel>.from(_cachedMoreMenu);
        
        print('📊 Using cached categories - PRABAYAR: ${_prabayarMenu.length}, PASCABAYAR: ${_pascabayarMenu.length}');
        setState(() {
          loading = false;
        });
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      var token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('https://app.payuni.co.id/api/v1/menu/1'),
        headers: {
          'Authorization': token,
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        final List data = jsonBody['data'] ?? [];
        
        // Debug: Log response API untuk bandingkan dengan yang Anda berikan
        print('🌐 MenuDepan API Response Status: ${response.statusCode}');
        print('🌐 MenuDepan API Response Length: ${data.length} items');
        
        // Debug: Log beberapa menu pertama untuk komparasi
        for (int i = 0; i < (data.length > 5 ? 5 : data.length); i++) {
          var item = data[i];
          print('📋 API Menu $i: ${item['name']} | ID: ${item['_id']} | Type: ${item['type']} | Category: ${item['category_id']}');
        }
        
        // Cari khusus menu TELKOM
        var telkomMenu = data.firstWhere((item) => item['name']?.toString()?.toLowerCase()?.contains('telkom') == true, orElse: () => null);
        if (telkomMenu != null) {
          print('🎯 TELKOM Menu dari API: ID=${telkomMenu['_id']}, Name=${telkomMenu['name']}, Type=${telkomMenu['type']}');
        }
        
        List<MenuModel> listMenu =
            data.map((e) => MenuModel.fromJson(e)).toList();

        // Sorting by orderNumber, yang null di bawah
        listMenu.sort((a, b) =>
            ((a.orderNumber ?? 9999).compareTo(b.orderNumber ?? 9999)));

        // Cache the data
        _cachedMenuData = List<MenuModel>.from(listMenu);
        _isDataLoaded = true;
        print('📊 Cached menu data: ${_cachedMenuData.length} items');

        _splitMenusByCategory(listMenu);
        
        // Cache hasil pemisahan kategori
        _cachedPrabayarMenu = List<MenuModel>.from(_prabayarMenu);
        _cachedPascabayarMenu = List<MenuModel>.from(_pascabayarMenu);
        _cachedPrabayarMoreMenu = List<MenuModel>.from(_prabayarMoreMenu);
        _cachedPascabayarMoreMenu = List<MenuModel>.from(_pascabayarMoreMenu);
        _cachedMoreMenu = List<MenuModel>.from(_moreMenu);
        
        // Preload submenu untuk menu yang sering diakses
        _preloadSubmenus(listMenu);
      } else {
        _prabayarMenu = [];
        _pascabayarMenu = [];
        _moreMenu = [];
        print('Failed to load menu: ${response.statusCode}');
      }
    } catch (e) {
      _prabayarMenu = [];
      _pascabayarMenu = [];
      _moreMenu = [];
      print('Error getMenu: $e');
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  void _splitMenusByCategory(List<MenuModel> listMenu) {
    // Separate menus by category (prepaid vs postpaid)
    // You may need to adjust this logic based on your actual data structure
    _prabayarMenu = [];
    _pascabayarMenu = [];
    _prabayarMoreMenu = [];
    _pascabayarMoreMenu = [];
    _moreMenu = [];

    // First, let's see what data we have
    print('📊 Total menu items: ${listMenu.length}');
    for (MenuModel menu in listMenu) {
      print('📋 Menu: ${menu.name} | type: ${menu.type} | jenis: ${menu.jenis} | category_id: ${menu.category_id}');
    }

    for (MenuModel menu in listMenu) {
      // More flexible categorization logic
      bool isPrabayar = false;
      bool isPascabayar = false;
      
      // Check if it's explicitly categorized
      if (menu.category_id != null && menu.category_id.isNotEmpty) {
        if (menu.category_id.toLowerCase().contains('prabayar') || 
            menu.category_id.toLowerCase().contains('prepaid')) {
          isPrabayar = true;
        } else if (menu.category_id.toLowerCase().contains('pascabayar') || 
                   menu.category_id.toLowerCase().contains('postpaid')) {
          isPascabayar = true;
        }
      }
      
      // Check by type and jenis
      if (menu.type == 1 || menu.jenis == 1) {
        isPrabayar = true;
      } else if (menu.type == 2 || menu.jenis == 2) {
        isPascabayar = true;
      }
      
      // If still not categorized, try to categorize by name
      if (!isPrabayar && !isPascabayar) {
        String menuName = menu.name.toLowerCase();
        if (menuName.contains('pulsa') || menuName.contains('token') || 
            menuName.contains('data') || menuName.contains('voucher') ||
            menuName.contains('dompet') || menuName.contains('inject')) {
          isPrabayar = true;
        } else if (menuName.contains('tagihan') || menuName.contains('bill') ||
                   menuName.contains('air') || menuName.contains('pdam')) {
          isPascabayar = true;
        }
      }
      
      // Default to prabayar if still not categorized
      if (!isPrabayar && !isPascabayar) {
        isPrabayar = true;
      }
      
      // Add to appropriate category
      if (isPrabayar) {
        _prabayarMenu.add(menu);
      } else if (isPascabayar) {
        _pascabayarMenu.add(menu);
      } else {
        _moreMenu.add(menu);
      }
    }

    print('📊 PRABAYAR items: ${_prabayarMenu.length}');
    print('📊 PASCABAYAR items: ${_pascabayarMenu.length}');
    print('📊 Other items: ${_moreMenu.length}');
 
    int prabayarLimit = 7;
    int pascabayarLimit = 77;  
    
    // Limit items per category and add "Lainnya" buttons
    if (_prabayarMenu.length > prabayarLimit) {
      print('📊 PRABAYAR: ${_prabayarMenu.length} items, limit: $prabayarLimit');
      print('📊 Moving ${_prabayarMenu.length - prabayarLimit} items to PRABAYAR More');
      
      // Clear existing items first
      _prabayarMoreMenu.clear();
      
      // Add items that exceed the limit
      _prabayarMoreMenu.addAll(_prabayarMenu.sublist(prabayarLimit));
      _prabayarMenu = _prabayarMenu.sublist(0, prabayarLimit);
      
      print('📊 PRABAYAR More now has: ${_prabayarMoreMenu.length} items');
      for (MenuModel item in _prabayarMoreMenu) {
        print('  📋 PRABAYAR More Item: ${item.name}');
      }
    } else {
      print('📊 PRABAYAR: ${_prabayarMenu.length} items, limit: $prabayarLimit - No items moved to More');
    }
    
    if (_pascabayarMenu.length > pascabayarLimit) {
      print('📊 PASCABAYAR: ${_pascabayarMenu.length} items, limit: $pascabayarLimit');
      print('📊 Moving ${_pascabayarMenu.length - pascabayarLimit} items to PASCABAYAR More');
      
      // Clear existing items first
      _pascabayarMoreMenu.clear();
      
      // Add items that exceed the limit
      _pascabayarMoreMenu.addAll(_pascabayarMenu.sublist(pascabayarLimit));
      _pascabayarMenu = _pascabayarMenu.sublist(0, pascabayarLimit);
      
      print('📊 PASCABAYAR More now has: ${_pascabayarMoreMenu.length} items');
      for (MenuModel item in _pascabayarMoreMenu) {
        print('  📋 PASCABAYAR More Item: ${item.name}');
      }
    } else {
      print('📊 PASCABAYAR: ${_pascabayarMenu.length} items, limit: $pascabayarLimit - No items moved to More');
    }

    // Add "Lainnya" buttons to each category separately
    // Only show "Lainnya" for PRABAYAR if it has more items
    if (_prabayarMoreMenu.isNotEmpty) {
      _prabayarMenu.add(MenuModel(
        jenis: 99,
        icon: 'https://dokumen.payuni.co.id/logo/Seepays/seepaysmenulainya.png',
        name: 'Lainnya',
        type: 99,
        category_id: 'prabayar', // Add category identifier
      ));
    }
    
    // Only show "Lainnya" for PASCABAYAR if it has more items
    if (_pascabayarMoreMenu.isNotEmpty) {
      _pascabayarMenu.add(MenuModel(
        jenis: 99,
        icon: 'https://dokumen.payuni.co.id/logo/Seepays/seepaysmenulainya.png',
        name: 'Lainnya',
        type: 99,
        category_id: 'pascabayar', // Add category identifier
      ));
    }

    setState(() {
      loading = false;
      failed = false;
    });
  }

  List<String> pkgName = [
    'com.mkrdigital.mobile',
    'id.outletpay.mobile',
    'id.payku.app',
    'com.eralink.mobileapk',
    'mobile.payuni.id',
    'com.esaldoku.mobileserpul',
    'com.talentapay.android',
    'mypay.co.id',
    'com.santrenpay.mobile',
    'com.seepaysbiller.app'
  ];

  onTapMenu(MenuModel menu) {
    print(
        '📌 Menu diklik: ${menu.name} | jenis: ${menu.jenis}, type: ${menu.type}, category_id: ${menu.category_id}, kodeProduk: ${menu.kodeProduk}');
    if (menu.jenis == 1) {
      print('➡️ Menu menuju ke: Pulsa');
      return Navigator.of(context).push(MaterialPageRoute(builder: (_) {
        return Pulsa(menu);
      }));
    } else if (menu.jenis == 2) {
      if (menu.category_id != null &&
          menu.category_id.isNotEmpty &&
          menu.type == 1) {
        print('➡️ Menu menuju ke: DetailDenom');
        return Navigator.of(context).push(PageTransition(
            child: DetailDenom(menu), type: PageTransitionType.rippleRightUp));
      } else if (menu.kodeProduk != null &&
          menu.kodeProduk.isNotEmpty &&
          menu.type == 2) {
        print('➡️ Menu menuju ke: DetailDenomPostpaid');
        return Navigator.of(context).push(PageTransition(
            child: DetailDenomPostpaid(menu),
            type: PageTransitionType.rippleRightUp));
      } else {
        if (menu.type == 3) {
          print('➡️ Menu menuju ke: DynamicPrepaidDenom');
          return Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DynamicPrepaidDenom(menu)));
        } else {
          print('➡️ Menu menuju ke: ListSubMenu (category_id kosong/null)');
          print('🔍 MenuDepan Debug: Mengirim menu ke ListSubMenu:');
          print('   📋 Menu ID: ${menu.id}');
          print('   📋 Menu Name: ${menu.name}');
          print('   📋 Menu Type: ${menu.type}');
          print('   📋 Menu Jenis: ${menu.jenis}');
          print('   📋 Menu Category ID: ${menu.category_id}');
          print('   📋 Menu Kode Produk: ${menu.kodeProduk}');
          return Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => ListSubMenu(menu)));
        }
      }
    } else if (menu.jenis == 4) {
      print('➡️ Menu menuju ke: ListGridMenu');
      return Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ListGridMenu(menu),
        ),
      );
    } else if (menu.jenis == 5 || menu.jenis == 6) {
      if (menu.category_id == null || menu.category_id.isEmpty) {
        print('➡️ Menu menuju ke: ListSubMenu');
        return Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ListSubMenu(menu),
          ),
        );
      } else if (pkgName.contains(packageName)) {
        print('➡️ Menu menuju ke: VoucherBulkPage');
        return Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VoucherBulkPage(menu),
          ),
        );
      } else {
        print('❌ Tidak ada navigasi untuk kondisi jenis ${menu.jenis}');
        return;
      }
    } else if (menu.jenis == 99) {
      print('➡️ Menu menuju ke: MorePage (Menu Lainnya)');
      
      // Determine which category's "Lainnya" was clicked
      List<MenuModel> itemsToShow;
      String categoryName = '';
      
      if (menu.category_id == 'prabayar') {
        itemsToShow = _prabayarMoreMenu;
        categoryName = 'PRABAYAR';
        print('📋 Menampilkan item PRABAYAR lainnya: ${_prabayarMoreMenu.length} items');
        for (MenuModel item in _prabayarMoreMenu) {
          print('  📋 PRABAYAR More: ${item.name}');
        }
      } else if (menu.category_id == 'pascabayar') {
        itemsToShow = _pascabayarMoreMenu;
        categoryName = 'PASCABAYAR';
        print('📋 Menampilkan item PASCABAYAR lainnya: ${_pascabayarMoreMenu.length} items');
        for (MenuModel item in _pascabayarMoreMenu) {
          print('  📋 PASCABAYAR More: ${item.name}');
        }
      } else {
        itemsToShow = _moreMenu;
        categoryName = 'LAINNYA';
        print('📋 Menampilkan item lainnya: ${_moreMenu.length} items');
        for (MenuModel item in _moreMenu) {
          print('  📋 OTHER More: ${item.name}');
        }
      }
      
      // Check if there are items to show
      if (itemsToShow.isEmpty) {
        // Show validation message when no products are available
        return showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Informasi'),
              content: Text('Produk $categoryName belum tersedia'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
      
      return Navigator.of(context).push(PageTransition(
        child: MorePage(
          itemsToShow, // Kirim menu sesuai kategori
          isKotak: widget.gradient != null ? widget.gradient : false,
        ),
        type: PageTransitionType.slideInUp,
      ));
    } else {
      print('❌ Tidak ada navigasi untuk jenis ${menu.jenis}');
    }
  }

  Widget _buildMenuCard(String title, List<MenuModel> menus, int crossAxisCount) {
    if (menus.isEmpty) return SizedBox.shrink();
    
    return Container(
      margin: EdgeInsets.only(bottom: 20.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          //SizedBox(height: 13.0),
          GridView.builder(
            shrinkWrap: true,
            primary: false,
            physics: NeverScrollableScrollPhysics(),
            itemCount: menus.length,
            itemBuilder: (_, int index) {
              MenuModel menu = menus[index];
              return Container(
                child: InkWell(
                  onTap: () => onTapMenu(menu),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                                              Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFA259FF).withOpacity(0.3),
                                blurRadius: 6,
                                offset: Offset(0, 9),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: CachedNetworkImage(
                            imageUrl: menu.icon,
                            width: 35,
                            height: 35,
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: 8.0),
                        Flexible(
                          child: Text(
                            menu.name,
                            style: TextStyle(
                                fontSize: 12.0,
                                color: Color(0xFFA259FF),
                                fontWeight: FontWeight.bold),
                            softWrap: true,
                            textAlign: TextAlign.center,
                          ),
                        )
                    ],
                  ),
                ),
              );
            },
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 2,
                childAspectRatio: 0.85,
                mainAxisSpacing: 4.0),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? LoadingMenuDepan(widget.grid, baris: widget.baris ?? 3)
        : Container(
            margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                children: [
                  // PRABAYAR Section
                  _buildMenuCard('PRABAYAR', _prabayarMenu, 4),
                  
                  // PASCABAYAR Section
                  _buildMenuCard('PASCABAYAR', _pascabayarMenu, 4),
                ],
              ),
            ),
          );
  }
  
  // Method untuk preload submenu yang sering diakses
  Future<void> _preloadSubmenus(List<MenuModel> menuList) async {
    print('🚀 Starting submenu preloading...');
    
    // Filter menu yang tidak punya category_id atau kodeProduk (biasanya parent menu)
    List<MenuModel> parentMenus = menuList.where((menu) => 
      (menu.category_id == null || menu.category_id.isEmpty) &&
      (menu.kodeProduk == null || menu.kodeProduk.isEmpty)
    ).toList();
    
    print('📋 Found ${parentMenus.length} parent menus to preload');
    
    for (MenuModel parentMenu in parentMenus) {
      // Skip jika sudah di-cache
      if (_cachedSubmenus.containsKey(parentMenu.id)) {
        print('✅ Submenu for ${parentMenu.name} already cached');
        continue;
      }
      
      try {
        final prefs = await SharedPreferences.getInstance();
        var token = prefs.getString('token');
        
        String apiEndpoint = 'https://app.payuni.co.id/api/v1/menu/${parentMenu.id}/child';
        print('🌐 Preloading submenu: $apiEndpoint');
        
        final response = await http.get(
          Uri.parse(apiEndpoint),
          headers: {
            'Authorization': token,
            'Accept': 'application/json',
          },
        );
        
        if (response.statusCode == 200) {
          final jsonBody = json.decode(response.body);
          final List data = jsonBody['data'] ?? [];
          List<MenuModel> submenuList = data.map((e) => MenuModel.fromJson(e)).toList();
          
          // Cache submenu
          _cachedSubmenus[parentMenu.id] = submenuList;
          // Juga simpan di global cache jika ada
          // _globalSubmenuCache[parentMenu.id] = submenuList;
          print('✅ Preloaded ${submenuList.length} submenus for ${parentMenu.name}');
          
          // Log submenu details
          for (MenuModel submenu in submenuList) {
            print('   📋 Cached submenu: ${submenu.name} | category_id: "${submenu.category_id}" | kodeProduk: "${submenu.kodeProduk}"');
          }
        } else {
          print('❌ Failed to preload submenu for ${parentMenu.name}: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ Error preloading submenu for ${parentMenu.name}: $e');
      }
    }
    
    print('🎯 Submenu preloading completed');
  }
  
  // Method untuk mendapatkan cached submenu
  static List<MenuModel> getCachedSubmenu(String menuId) {
    return _cachedSubmenus[menuId] ?? [];
  }
}
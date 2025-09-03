// @dart=2.9

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_page_transition/flutter_page_transition.dart';
import 'package:mobile/models/menu.dart';

// Import necessary pages for navigation - using SEEPAY specific ones
import 'package:mobile/screen/detail-denom/detail-denom.dart';
import 'package:mobile/screen/detail-denom-postpaid/detail-postpaid.dart';
import 'package:mobile/screen/dynamic-prepaid/dynamic-denom.dart';
import 'package:mobile/screen/list-grid-menu/list-grid-menu.dart';
import 'list-sub-menu.dart';
import 'pulsa.dart';
import 'package:mobile/screen/transaksi/voucher_bulk.dart';

// Import SEEPAY specific detail pages
import 'detail-denom.dart';
import 'detail-denom-postpaid.dart';

class MorePage extends StatefulWidget {
  final List<MenuModel> menus;
  final bool isKotak;

  MorePage(this.menus, {this.isKotak = false});

  @override
  _MorePageState createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Product Lainnya'),
              centerTitle: true,
            ),
            expandedHeight: 200.0,
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Container(
                margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  primary: false,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: widget.menus.length,
                  itemBuilder: (_, int index) {
                    MenuModel menu = widget.menus[index];
                    return Container(
                      child: InkWell(
                        onTap: () => _onTapMenu(menu),
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
                                errorWidget: (context, url, error) => Container(
                                  width: 35,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFA259FF).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 20,
                                    color: Color(0xFFA259FF),
                                  ),
                                ),
                                placeholder: (context, url) => Container(
                                  width: 35,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFA259FF).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA259FF)),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 12.0),
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
                      crossAxisCount: 4,
                      crossAxisSpacing: 2,
                      childAspectRatio: 0.95,
                      mainAxisSpacing: 4.0),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  void _onTapMenu(MenuModel menu) {
    print('📌 MorePage Menu diklik: ${menu.name} | jenis: ${menu.jenis}, type: ${menu.type}, category_id: ${menu.category_id}, kodeProduk: ${menu.kodeProduk}');
    
    if (menu.jenis == 1) {
      print('➡️ Menu menuju ke: Pulsa');
      Navigator.of(context).push(MaterialPageRoute(builder: (_) {
        return Pulsa(menu);
      }));
    } else if (menu.jenis == 2) {
      if (menu.category_id != null &&
          menu.category_id.isNotEmpty &&
          menu.type == 1) {
        print('➡️ Menu menuju ke: SeepaysDetailDenom');
        Navigator.of(context).push(PageTransition(
            child: SeepaysDetailDenom(menu), type: PageTransitionType.rippleRightUp));
      } else if (menu.kodeProduk != null &&
          menu.kodeProduk.isNotEmpty &&
          menu.type == 2) {
        print('➡️ Menu menuju ke: SeepaysDetailDenomPostpaid');
        Navigator.of(context).push(PageTransition(
            child: SeepaysDetailDenomPostpaid(menu),
            type: PageTransitionType.rippleRightUp));
      } else {
        if (menu.type == 3) {
          print('➡️ Menu menuju ke: DynamicPrepaidDenom');
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DynamicPrepaidDenom(menu)));
        } else {
          print('➡️ Menu menuju ke: ListSubMenu (category_id kosong/null)');
          print('🔍 MorePage Debug: Mengirim menu ke ListSubMenu:');
          print('   📋 Menu ID: ${menu.id}');
          print('   📋 Menu Name: ${menu.name}');
          print('   📋 Menu Type: ${menu.type}');
          print('   📋 Menu Jenis: ${menu.jenis}');
          print('   📋 Menu Category ID: ${menu.category_id}');
          print('   📋 Menu Kode Produk: ${menu.kodeProduk}');
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => ListSubMenu(menu)));
        }
      }
    } else if (menu.jenis == 4) {
      print('➡️ Menu menuju ke: ListGridMenu');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ListGridMenu(menu),
        ),
      );
    } else if (menu.jenis == 5) {
      print('➡️ Menu menuju ke: VoucherBulkPage');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VoucherBulkPage(menu),
        ),
      );
    } else {
      print('❌ Jenis menu tidak dikenali: ${menu.jenis}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Menu belum tersedia'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}

// @dart=2.9

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/Products/seepays/layout/history.dart';
import 'package:mobile/Products/seepays/layout/home2.dart';
import 'package:mobile/Products/seepays/layout/profile.dart';
import 'package:mobile/bloc/ConfigApp.dart';
import 'package:mobile/component/webview.dart';
import 'package:mobile/Products/lariz/layout/qris/qris_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile/screen/profile/cs/cs.dart';

class MainApp extends StatefulWidget {
  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int pageIndex = 0;

  List<Widget> get halaman => [
        Home2App(),
        HistoryPage(),
        _LivechatTab(),
        ProfilePage(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.9),
              blurRadius: 8.0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.white,
          child: CachedNetworkImage(
            imageUrl: 'https://dokumen.payuni.co.id/logo/payku/qris.png',
            color: Colors.black,
            width: 40.0,
            height: 40.0,
          ),
          elevation: 0.0,
                      onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => QrisPage(initIndex: 1)));
            },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: halaman[pageIndex],
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        child: Container(
          color: Colors.white.withOpacity(0.3),
          height: 55.0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              // Home (Logo App)
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => pageIndex = 0);
                  },
                  child: Container(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Column(
                      children: <Widget>[
                        Image.asset(
                          "assets/seepaysicon.png",
                          width: 25.0,
                          height: 25.0,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.apps,
                            color: pageIndex == 0
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                          ),
                        ),
                        SizedBox(height: 3.0),
                        Text('Home', style: TextStyle(fontSize: 10.0))
                      ],
                    ),
                  ),
                ),
              ),
              // Riwayat
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => pageIndex = 1);
                  },
                  child: Container(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Column(
                      children: <Widget>[
                        CachedNetworkImage(
                          imageUrl: 'https://cdn-icons-png.flaticon.com/512/8118/8118496.png',
                          color: pageIndex == 1
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                          width: 25.0,
                          height: 25.0,
                        ),
                        SizedBox(height: 3.0),
                        Text('Riwayat', style: TextStyle(fontSize: 10.0))
                      ],
                    ),
                  ),
                ),
              ),
              // Center gap for FAB (Static QR)
              SizedBox(width: 60),
              // Bantuan/Livechat
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => pageIndex = 2);
                  },
                  child: Container(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Column(
                      children: <Widget>[
                        Icon(
                          Icons.forum_rounded,
                          color: pageIndex == 2
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                          size: 25.0,
                        ),
                        SizedBox(height: 3.0),
                        Text('Livechat', style: TextStyle(fontSize: 10.0))
                      ],
                    ),
                  ),
                ),
              ),
              // Akun/Profile
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => pageIndex = 3);
                  },
                  child: Container(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Column(
                      children: <Widget>[
                        Icon(
                          Icons.person_rounded,
                          color: pageIndex == 3
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                          size: 25.0,
                        ),
                        SizedBox(height: 3.0),
                        Text('Akun', style: TextStyle(fontSize: 10.0))
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LivechatTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CS();
  }
}

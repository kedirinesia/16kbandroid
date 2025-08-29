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
import 'package:mobile/Products/seepays/config.dart' as seepaysConfig;
import 'package:webview_flutter/webview_flutter.dart';

class MainApp extends StatefulWidget {
  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int pageIndex = 0;

  List<Widget> get halaman => [
        Home2App(),
        HistoryPage(),
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
                    // Navigate to livechat webview directly
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _LivechatWebview(
                          url: seepaysConfig.liveChat,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Column(
                      children: <Widget>[
                        Icon(
                          Icons.forum_rounded,
                          color: Colors.grey,
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
                    setState(() => pageIndex = 2);
                  },
                  child: Container(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Column(
                      children: <Widget>[
                        Icon(
                          Icons.person_rounded,
                          color: pageIndex == 2
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

class _LivechatWebview extends StatefulWidget {
  final String url;
  
  _LivechatWebview({this.url});
  
  @override
  _LivechatWebviewState createState() => _LivechatWebviewState();
}

class _LivechatWebviewState extends State<_LivechatWebview> {
  WebViewController _controller;
  bool isLoading = true;
  bool canGoBack = false;
  bool canGoForward = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text(
          'Livechat SEEPAYS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFFA259FF),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebView(
            initialUrl: widget.url,
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController webViewController) {
              _controller = webViewController;
            },
            onPageFinished: (url) {
              setState(() {
                isLoading = false;
              });
              // Check navigation state
              _checkNavigationState();
            },
            onWebResourceError: (WebResourceError error) {
              setState(() {
                isLoading = false;
              });
              // Show error message
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal memuat livechat: ${error.description}'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              });
            },
            navigationDelegate: (NavigationRequest request) {
              // Allow all navigation
              return NavigationDecision.navigate;
            },
          ),
          if (isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFA259FF),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Memuat Livechat...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: canGoBack ? Color(0xFFA259FF) : Colors.grey,
              ),
              onPressed: canGoBack
                  ? () async {
                      if (await _controller.canGoBack()) {
                        await _controller.goBack();
                        _checkNavigationState();
                      }
                    }
                  : null,
            ),
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: Color(0xFFA259FF),
              ),
              onPressed: () => _controller.reload(),
            ),
            IconButton(
              icon: Icon(
                Icons.arrow_forward_ios,
                color: canGoForward ? Color(0xFFA259FF) : Colors.grey,
              ),
              onPressed: canGoForward
                  ? () async {
                      if (await _controller.canGoForward()) {
                        await _controller.goForward();
                        _checkNavigationState();
                      }
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _checkNavigationState() async {
    if (mounted) {
      bool back = await _controller.canGoBack();
      bool forward = await _controller.canGoForward();
      if (mounted) {
        setState(() {
          canGoBack = back;
          canGoForward = forward;
        });
      }
    }
  }
}

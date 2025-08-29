// @dart=2.9

import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

 
import 'package:http/http.dart' as http;
import 'package:mobile/Products/seepays/layout/carouselDepan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_page_transition/flutter_page_transition.dart';
import 'package:intl/intl.dart';
import 'package:mobile/bloc/Bloc.dart';
import 'package:mobile/bloc/ConfigApp.dart';
import 'package:mobile/component/rewards.dart';
 
import 'package:mobile/screen/profile/cs/cs.dart';
import 'package:mobile/screen/transfer_saldo/transfer_saldo.dart';
import '../../../component/card_info.dart';
 
 

 
 
import '../../seepays/layout/menudepan.dart';
 

class CarouselBannerAPI extends StatefulWidget {
  const CarouselBannerAPI({Key key}) : super(key: key);

  @override
  State<CarouselBannerAPI> createState() => _CarouselBannerAPIState();
}

class _CarouselBannerAPIState extends State<CarouselBannerAPI> {
  List<dynamic> banners = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBanner();
  }

  Future<void> fetchBanner() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');  
      print('DEBUG TOKEN: $token');
      if (token == null || token.isEmpty) {
        setState(() {
          isLoading = false;
        });
        print('DEBUG: Token null/kosong!');
        return;
      }

      final response = await http.get(
        Uri.parse('https://app.payuni.co.id/api/v1/banner/list?limit=3'),
        headers: {'Authorization': token},
      );

      print('DEBUG STATUS: ${response.statusCode}');
      print('DEBUG BODY: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResp = json.decode(response.body);
        setState(() {
          banners = jsonResp['data'] ?? [];
          isLoading = false;
        });
        print('DEBUG BANNERS: $banners');
      } else {
        setState(() {
          isLoading = false;
        });
        print('DEBUG: Response status bukan 200');
      }
    } catch (e) {
      print('DEBUG ERROR: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG isLoading: $isLoading');
    print('DEBUG banners: $banners');
    if (isLoading) {
      return Container(
        height: 110,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (banners.isEmpty) {
      return Container(
        height: 110,
        child: Center(child: Text('Banner Not Found ', style: TextStyle(color: Colors.grey))),
      );
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: 110,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.92,
        aspectRatio: 16 / 5,
      ),
      items: banners.map((banner) {
        return Builder(
          builder: (BuildContext context) {
            return GestureDetector(
              onTap: () {
           
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12, blurRadius: 8, offset: Offset(0, 3),
                    ),
                  ],
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        banner['cover'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: Center(child: Icon(Icons.broken_image)),
                        ),
                        loadingBuilder: (ctx, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(child: CircularProgressIndicator());
                        },
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          width: double.infinity,
                          color: Colors.black.withOpacity(0.24),
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          child: Text(
                            banner['title'] ?? '',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

// Home2App class
class Home2App extends StatefulWidget {
  @override
  _Home2AppState createState() => _Home2AppState();
}

class _Home2AppState extends State<Home2App> with SingleTickerProviderStateMixin {
  AnimationController animationController;
 final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  // Function to handle refresh
  Future<void> _onRefresh() async {
    try {
      // Refresh banner data
      setState(() {
        // Trigger rebuild to refresh banner
      });
      
      // Add a small delay to show refresh animation
      await Future.delayed(Duration(milliseconds: 800));
      
      // You can add more refresh logic here if needed
      // For example, refresh user data, balance, etc.
      
    } catch (e) {
      print('Error during refresh: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    
    final double headerHeight = 240;
    final double saldoCardTop = 140;  
    final double saldoCardHeight =120;
    final double floatingGap = 20;
    final double floatingCardTop = saldoCardTop + saldoCardHeight + floatingGap;

    return Scaffold(
      backgroundColor: Color(0xFFF6F7FB),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _onRefresh,
        color: Color(0xFFA259FF),
        backgroundColor: Colors.white,
        strokeWidth: 3.0,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Stack(
            children: <Widget>[
                          // HEADER GRADIENT D SHAPE
              Positioned(
                top: 30,
                left: -120,
                right: -10,
                child: Center(
                  child: Container(
                    width: 830,
                    height: 340,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(0),
                        bottomLeft: Radius.circular(20),
                        topRight: Radius.elliptical(600, 200), // Menggunakan elliptical untuk lengkungan oval
                        bottomRight: Radius.circular(0),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFA259FF),    
                          Color(0xFF8B4BCF),   
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ),
   

              // TITLE TEXT - SEEPAYS AND POINT
              Positioned(
                top: 50, // Sesuaikan dengan header oval elliptical
                left: 0,
                child: Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "SEEPAY",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Point: ${bloc.poin.valueWrapper?.value ?? 0}",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // APP LOGO - TOP RIGHT
              Positioned(
                top: 30, // Sesuaikan dengan header oval elliptical
                right: 20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/seepaysicon.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.apps,
                            color: Colors.white,
                            size: 30,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // SALDO CARD DI HEADER
              Positioned(
                top: saldoCardTop,
                left: 40,
                right: 80,
                child: Container(
                  height: saldoCardHeight,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.11),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Saldo",
                            style: TextStyle(
                               color: Colors.white,
                              fontSize: 15  
                              
                            
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            "Rp ${NumberFormat.decimalPattern('id').format(bloc.saldo.valueWrapper?.value ?? 0)}",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/topup');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 26, vertical: 10),
                        ),
                        child: Text(
                          "Topup",
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      )
                    ],
                  ),
                ),
              ),

            //  SizedBox(height: 20),

              // FLOATING MENU CARD, RAPAT DENGAN SALDO
              Positioned(
                top: floatingCardTop,
                left: 26,
                right: 30,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 22, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MenuImageItem(
                        image: 'assets/img/money.png',
                        label: 'Hadiah',
                        color: Colors.purple,
                        onTap: () => Navigator.of(context).pushNamed('/rewards'),
                      ),
                      _MenuImageItem(
                        image: 'assets/commist.png',
                        label: 'Komisi',
                        color: Colors.purple,
                        onTap: () => Navigator.of(context).pushNamed('/komisi'),
                      ),
                      _MenuImageItem(
                        image: 'assets/img/next.png',
                        label: 'Transfer',
                        color: Colors.purple,
                        onTap: () {
                          Navigator.of(context).push(PageTransition(
                            child: TransferSaldo(''),
                            type: PageTransitionType.rippleRightUp,
                            duration: Duration(milliseconds: 500),
                          ));
                        },
                      ),
                      _MenuImageItem(
                        image: 'assets/img/people.png',
                        label: 'Bantuan',
                        color: Colors.purple,
                        onTap: () {
                          Navigator.of(context).push(PageTransition(
                            child: CS(),
                            type: PageTransitionType.rippleRightUp,
                            duration: Duration(milliseconds: 500),
                          ));
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // MAIN CONTENT
            Column(
      children: [
        // Bagian Atas dengan Padding
        Container(
          margin: EdgeInsets.only(top: floatingCardTop + 90),
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 60),
            //  SectionTitle(title: 'Produk'),
               
              MenuDepan(grid: 5, gradient: true),
              // /SizedBox(height: 8),
          CarouselDepan(), 
            ],
          ),
        ),

        

        SizedBox(height: 40),

         
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SectionTitle(title: 'Info '),
              Text(
                'Mengenal Lebih Jauh Aplikasi ${configAppBloc.namaApp.valueWrapper?.value}',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              SizedBox(height: 10),
              
              CardInfo(),
              SizedBox(height: 20),
              SectionTitle(title: 'Hadiah Unggulan'),
              SizedBox(height: 4),
              Text(
                'Reward Akan Di Berikan Ke Member ${configAppBloc.namaApp.valueWrapper?.value}',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              SizedBox(height: 14),
              RewardComponent(),
              SizedBox(height: 38),
            ],
          ),
        ),
      ],
    )
            ],
          ),
        ),
      ),
    );
  }
}

// --------- Icon Berbasis Image Asset ---------
class _MenuImageItem extends StatelessWidget {
  final String image;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuImageItem({
    Key key,
    @required this.image,
    @required this.label,
    this.color = Colors.green,
    @required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Image.asset(
                image,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(height: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({Key key, @required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 25, bottom: 3),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w300,
          color: Colors.black87,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
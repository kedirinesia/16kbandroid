// @dart=2.9

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mobile/bloc/Api.dart';
import 'package:mobile/config.dart';
import 'package:mobile/models/postpaid.dart';
import 'package:mobile/modules.dart';
import 'package:mobile/screen/detail-denom-postpaid/detail-postpaid.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/bloc/Bloc.dart' show bloc;
import 'package:mobile/screen/transaksi/detail_postpaid.dart';
import 'package:mobile/screen/transaksi/verifikasi_pin.dart';
import 'package:package_info_plus/package_info_plus.dart';

abstract class DetailDenomPostpaidController extends State<DetailDenomPostpaid>
    with TickerProviderStateMixin {
  TextEditingController idpel = TextEditingController();
  TextEditingController nominal = TextEditingController();
  TextEditingController namaController = TextEditingController();

  bool loading = false;
  bool isChecked = false;
  bool boxFavorite = true;
  PostpaidInquiryModel inq;
  String menuLogo = '';

  // Suggest numbers variables - EKSKLUSIF UNTUK PAYUNIOVO
  String packageName = '';
  List<String> suggestNumbers = [];
  bool loadingSuggest = false;

  @override
  void initState() {
    super.initState();
    print('=== DetailDenomPostpaidController initState() START ===');
    print('Menu Name: ${widget.menu.name}');
    print('Menu Category ID: ${widget.menu.category_id}');
    
    print('Calling _getPackageName()...');
    _getPackageName().then((_) {
      print('✅ _getPackageName() completed, now calling getSuggestNumbers()...');
      getSuggestNumbers();
    });
    
    print('Calling _getMenuLogo()...');
    _getMenuLogo();
    print('getSuggestNumbers() scheduled (after _getPackageName)');
    print('=== DetailDenomPostpaidController initState() END ===');
  }

  Future<void> _getPackageName() async {
    print('=== _getPackageName() CALLED (POSTPAID) ===');
    final info = await PackageInfo.fromPlatform();
    print('Package Info (POSTPAID): ${info.packageName}');
    setState(() {
      packageName = info.packageName;
    });
    print('Package Name Set (POSTPAID): $packageName');
    print('=== END _getPackageName() (POSTPAID) ===');
  }

  Future<void> getSuggestNumbers() async {
    print('=== getSuggestNumbers() CALLED (POSTPAID) ===');
    print('Package Name (POSTPAID): $packageName');
    print('Menu Name (POSTPAID): ${widget.menu.name}');
    print('Menu Category ID (POSTPAID): ${widget.menu.category_id}');
    
    // FITUR SUGGEST HISTORY NOMOR PEMBELI - EKSKLUSIF UNTUK APLIKASI PAYUNIOVO
    if (packageName != 'mobile.payuni.id' && packageName != 'co.payuni.id') {
      print('❌ Package name tidak didukung (POSTPAID): $packageName');
      print('❌ Supported packages: mobile.payuni.id, co.payuni.id');
      setState(() {
        suggestNumbers = [];
      });
      return;
    }
    
    print('✅ Package name didukung (POSTPAID): $packageName');
    print('✅ Akan melanjutkan ke API call (POSTPAID)');
    
    try {
      print('🔄 Setting loadingSuggest to true');
      setState(() {
        loadingSuggest = true;
      });
      print('✅ loadingSuggest set to: $loadingSuggest');
      
      // API khusus Payuniovo untuk suggest numbers
      final String apiUrl = 'https://payuni-app.findig.id/api/v1/trx/lastTransaction?kategori_id=${widget.menu.category_id}&limit=10&skip=0';
      print('🌐 API URL: $apiUrl');
      print('🔑 Authorization Header: ${bloc.token.valueWrapper?.value}');
      
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': bloc.token.valueWrapper?.value,
        },
      );
      
      print('=== DEBUG SUGGEST NUMBERS (POSTPAID) ===');
      print('📡 HTTP Request completed');
      print('🌐 API Endpoint: $apiUrl');
      print('📊 Response Status: ${response.statusCode}');
      print('📄 Response Headers: ${response.headers}');
      print('📝 Response Body: ${response.body}');
      print('📏 Response Body Length: ${response.body.length}');
      
      if (response.statusCode == 200) {
        print('✅ HTTP 200 OK - Processing response data');
        
        // Response langsung berupa array
        try {
          final List<dynamic> datas = json.decode(response.body) as List<dynamic>;
          print('✅ JSON parsing successful');
          print('📊 Parsed Data (POSTPAID): $datas');
          print('📊 Data Count (POSTPAID): ${datas.length}');
          print('📊 Data Type: ${datas.runtimeType}');
          
          if (datas.isEmpty) {
            print('⚠️ Response data kosong - tidak ada transaksi');
            setState(() {
              suggestNumbers = [];
            });
            return;
          }
          
          // Sort by tanggal desc for recency
          print('🔄 Sorting data by tanggal (descending)');
          datas.sort((a, b) {
            final String ac = (a['tanggal'] ?? '');
            final String bc = (b['tanggal'] ?? '');
            print('📅 Item A tanggal: "$ac"');
            print('📅 Item B tanggal: "$bc"');
            
            DateTime ad, bd;
            try { 
              ad = DateTime.parse(ac); 
              print('✅ Item A parsed: $ad');
            } catch (e) { 
              ad = DateTime.fromMillisecondsSinceEpoch(0); 
              print('❌ Item A parse error: $e, using default: $ad');
            }
            try { 
              bd = DateTime.parse(bc); 
              print('✅ Item B parsed: $bd');
            } catch (e) { 
              bd = DateTime.fromMillisecondsSinceEpoch(0); 
              print('❌ Item B parse error: $e, using default: $bd');
            }
            
            final result = bd.compareTo(ad);
            print('🔄 Sort result: $result (${bd.compareTo(ad)})');
            return result;
          });
          
          print('✅ Data sorting completed');
          print('📊 Sorted Data (first 3 items): ${datas.take(3).toList()}');
          
          final Set<String> uniqueTargets = <String>{};
          print('🔄 Starting data filtering...');
          
          for (int i = 0; i < datas.length; i++) {
            final dynamic item = datas[i];
            print('--- Processing Item $i ---');
            print('📄 Raw Item: $item');
            
            final String tujuanItem = (item['tujuan'] ?? '').toString().trim();
            print('📱 Tujuan Item: "$tujuanItem"');
            print('📏 Tujuan Length: ${tujuanItem.length}');
            
            if (tujuanItem.isEmpty) {
              print('❌ Tujuan kosong, skip item');
              continue;
            }
            
            // Filter untuk postpaid - terima semua format yang masuk dari API
            // PLN: ID Pelanggan (bisa 12 digit, dimulai dengan angka apapun)
            // HP: Nomor HP (bisa dimulai dengan 08, 62, dll)
            // Lainnya: ID pelanggan untuk layanan lain
            if (tujuanItem.length >= 8 && tujuanItem.length <= 20) {
              print('✅ Nomor valid (${tujuanItem.length} digit), adding to targets');
              uniqueTargets.add(tujuanItem);
              print('📊 Current unique targets: $uniqueTargets');
              print('📊 Current count: ${uniqueTargets.length}');
              
              if (uniqueTargets.length >= 5) {
                print('🛑 Reached limit of 5, stopping');
                break;
              }
            } else {
              print('❌ Nomor tidak valid: length=${tujuanItem.length}');
            }
            print('--- End Processing Item $i ---');
          }
          
          print('✅ Data filtering completed');
          print('📊 Final Unique Targets: $uniqueTargets');
          print('📊 Final Count: ${uniqueTargets.length}');
          
          setState(() {
            suggestNumbers = uniqueTargets.toList();
          });
          print('✅ suggestNumbers updated in state: $suggestNumbers');
          
        } catch (e) {
          print('❌ JSON parsing error: $e');
          print('❌ Stack trace: ${StackTrace.current}');
          setState(() {
            suggestNumbers = [];
          });
        }
      } else {
        print('❌ API Response Error (POSTPAID): ${response.statusCode}');
        print('❌ Response Body: ${response.body}');
        setState(() {
          suggestNumbers = [];
        });
      }
    } catch (e) {
      print('❌ Exception in getSuggestNumbers (POSTPAID): $e');
      print('❌ Exception type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');
      setState(() {
        suggestNumbers = [];
      });
      print('✅ suggestNumbers set to empty array due to exception');
    } finally {
      print('🔄 Finally block - setting loadingSuggest to false');
      setState(() {
        loadingSuggest = false;
      });
      print('✅ loadingSuggest set to: $loadingSuggest');
      print('✅ Final suggestNumbers state: $suggestNumbers');
      print('=== END getSuggestNumbers (POSTPAID) ===');
    }
  }

  void selectSuggestNumber(String number) {
    setState(() {
      idpel.text = number;
    });
    print('✅ Selected suggest number: $number');
  }

  Future<void> _getMenuLogo() async {
    try {
      http.Response response = await http.get(
        Uri.parse('$apiUrl/product/${widget.menu.category_id}'),
        headers: {
          'Authorization': bloc.token.valueWrapper.value,
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          menuLogo = json.decode(response.body)['url_image'] ?? '';
        });
      }
    } catch (err) {
      print('ERROR: $err');
    }
  }

  void cekTagihan(String kodeProduk) async {
    if (idpel.text.isEmpty) return;
    if (widget.menu.bebasNominal) {
      bool confirm = await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
                  title: Text('Nominal'),
                  content: TextFormField(
                      controller: nominal,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                          prefixText: 'Rp  ',
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey)))),
                  actions: <Widget>[
                    TextButton(
                        child: Text('Lanjut'.toUpperCase()),
                        onPressed: () {
                          if (nominal.text.isEmpty) return;
                          if (int.parse(nominal.text) <= 0) return;
                          Navigator.of(ctx).pop(true);
                        }),
                    TextButton(
                        child: Text('Batal'.toUpperCase()),
                        onPressed: () => Navigator.of(ctx).pop())
                  ]));
      if (confirm == null) return;
    }
    setState(() {
      loading = true;
    });
    Map<String, dynamic> dataToSend;
    if (widget.menu.bebasNominal) {
      dataToSend = {
        'kode_produk': kodeProduk,
        'tujuan': idpel.text,
        'nominal': int.parse(nominal.text),
        'counter': 1
      };
    } else {
      dataToSend = {
        'kode_produk': kodeProduk,
        'tujuan': idpel.text,
        'counter': 1
      };
    }

    http.Response response =
        await http.post(Uri.parse('$apiUrl/trx/postpaid/inquiry'),
            headers: {
              'Authorization': bloc.token.valueWrapper?.value,
              'Content-Type': 'application/json'
            },
            body: json.encode(dataToSend));

    if (response.statusCode == 200) {
      inq = PostpaidInquiryModel.fromJson(json.decode(response.body)['data']);
      isChecked = true;
    } else {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                  title: Text('Inquiry Gagal'),
                  content: Text(json.decode(response.body)['message']),
                  actions: <Widget>[
                    TextButton(
                        child: Text(
                          'TUTUP',
                          style: TextStyle(
                            color: packageName == 'com.lariz.mobile'
                                ? Theme.of(context).secondaryHeaderColor
                                : Theme.of(context).primaryColor,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop())
                  ]));
    }

    checkNumberFavorite(idpel.text); // check number favorite

    setState(() {
      loading = false;
    });
  }

  void bayar() async {
    if (!isChecked) return;
    String pin = await Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => VerifikasiPin()));
    if (pin != null) {
      sendDeviceToken();
      http.Response response =
          await http.post(Uri.parse('$apiUrl/trx/postpaid/purchase'),
              headers: {
                'Authorization': bloc.token.valueWrapper?.value,
                'Content-Type': 'application/json'
              },
              body: json.encode({'tracking_id': inq.trackingId, 'pin': pin}));
      print(response.body);
      if (response.statusCode == 200) {
        PostpaidPurchaseModel data =
            PostpaidPurchaseModel.fromJson(json.decode(response.body)['data']);
        // TrxModel trx = TrxModel(id: data.id);
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => DetailPostpaid(data)));
        // Navigator.of(context).pushReplacement(
        //     MaterialPageRoute(builder: (_) => DetailTransaksi(trx)));
      } else {
        String message = json.decode(response.body)['message'];
        setState(() {
          loading = false;
        });
        showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
                    title: Text('Pembayaran Gagal'),
                    content: Text(message),
                    actions: <Widget>[
                      TextButton(
                          child: Text(
                            'TUTUP',
                            style: TextStyle(
                              color: packageName == 'com.lariz.mobile'
                                  ? Theme.of(context).secondaryHeaderColor
                                  : Theme.of(context).primaryColor,
                            ),
                          ),
                          onPressed: () => Navigator.of(ctx).pop())
                    ]));
      }
    }
  }

  void checkNumberFavorite(String tujuan) async {
    setState(() {
      idpel.text = tujuan;
    });

    Map<String, dynamic> dataToSend = {'tujuan': tujuan, 'type': 'postpaid'};

    http.Response response =
        await http.post(Uri.parse('$apiUrl/favorite/checkNumber'),
            headers: {
              'Authorization': bloc.token.valueWrapper?.value,
              'Content-Type': 'application/json',
            },
            body: json.encode(dataToSend));

    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      setState(() {
        boxFavorite = !responseData['data'];
      });
    } else {
      String message = json.decode(response.body)['message'] ??
          'Terjadi kesalahan pada server';
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
                child: Text(
                  'TUTUP',
                  style: TextStyle(
                    color: packageName == 'com.lariz.mobile'
                        ? Theme.of(context).secondaryHeaderColor
                        : Theme.of(context).primaryColor,
                  ),
                ),
                onPressed: () => Navigator.of(ctx).pop()),
          ],
        ),
      );

      setState(() {
        boxFavorite = true;
      });
    }
  }

  void simpanFavorite() async {
    if (idpel.text == '' || namaController.text == '') {
      showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                  content: Text("Nomor Tujuan dan Nama Tidak Boleh Kosong !"),
                  actions: [
                    TextButton(
                        child: Text(
                          'TUTUP',
                          style: TextStyle(
                            color: packageName == 'com.lariz.mobile'
                                ? Theme.of(context).secondaryHeaderColor
                                : Theme.of(context).primaryColor,
                          ),
                        ),
                        onPressed: Navigator.of(ctx).pop)
                  ]));
    } else {
      setState(() {
        loading = true;
      });

      var dataToSend = {
        'tujuan': idpel.text,
        'nama': namaController.text,
        'type': 'postpaid',
      };

      http.Response response =
          await http.post(Uri.parse('$apiUrl/favorite/saveNumber'),
              headers: {
                'Authorization': bloc.token.valueWrapper?.value,
                'Content-Type': 'application/json',
              },
              body: json.encode(dataToSend));

      String message = json.decode(response.body)['message'] ??
          'Terjadi kesalahan pada server';
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
                child: Text(
                  'TUTUP',
                  style: TextStyle(
                    color: packageName == 'com.lariz.mobile'
                        ? Theme.of(context).secondaryHeaderColor
                        : Theme.of(context).primaryColor,
                  ),
                ),
                onPressed: () => Navigator.of(ctx).pop()),
          ],
        ),
      );

      setState(() {
        loading = false;
      });
    }
  }

  Widget loadingWidget() {
    return Container(
        width: double.infinity,
        height: double.infinity,
        child: Center(
            child: SpinKitThreeBounce(
                color: packageName == 'com.lariz.mobile'
                    ? Theme.of(context).secondaryHeaderColor
                    : Theme.of(context).primaryColor,
                size: 35)));
  }

  Widget formFavorite() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.1),
                offset: Offset(5, 10),
                blurRadius: 20),
          ]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Simpan Untuk Transaksi Selanjutnya',
                  style: TextStyle(
                      color: packageName == 'com.lariz.mobile'
                          ? Theme.of(context).secondaryHeaderColor
                          : Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold)),
              Icon(
                Icons.receipt,
                color: packageName == 'com.lariz.mobile'
                    ? Theme.of(context).secondaryHeaderColor
                    : Theme.of(context).primaryColor,
              )
            ],
          ),
          Divider(),
          SizedBox(height: 10),
          TextFormField(
            controller: idpel,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                labelText: 'Nomor Tujuan',
                prefixIcon: Icon(Icons.contacts)),
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: namaController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                labelText: 'Nama',
                prefixIcon: Icon(Icons.person)),
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 40.0,
            child: TextButton(
              child: Text(
                'SIMPAN',
                style: TextStyle(
                  color: packageName == 'com.lariz.mobile'
                      ? Theme.of(context).secondaryHeaderColor
                      : Theme.of(context).primaryColor,
                ),
              ),
              onPressed: () => simpanFavorite(),
            ),
          )
        ],
      ),
    );
  }
}

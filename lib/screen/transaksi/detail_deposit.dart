// @dart=2.9

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/bloc/Bloc.dart';
import 'package:mobile/bloc/ConfigApp.dart';
import 'package:mobile/bloc/TemplateConfig.dart';
import 'package:mobile/models/deposit.dart';
import 'package:mobile/modules.dart';
import 'package:mobile/provider/analitycs.dart';
import 'package:mobile/screen/topup/bank/transfer-deposit.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DetailDeposit extends StatefulWidget {
  final DepositModel dep;
  DetailDeposit(this.dep);
  @override
  _DetailDepositState createState() => _DetailDepositState();
}

class _DetailDepositState extends DetailDepositController {
  Widget fab() {
    print('🔍 [DETAIL DEPOSIT] fab() called');
    print('🔍 [DETAIL DEPOSIT] Deposit status: ${widget.dep.statusModel.status}');
    print('🔍 [DETAIL DEPOSIT] Deposit type: ${widget.dep.type}');
    print('🔍 [DETAIL DEPOSIT] VA name: ${widget.dep.vaname}');
    
    if (widget.dep.statusModel.status == 0 &&
        (widget.dep.type == 1 || widget.dep.type == 2)) {
      print('🔍 [DETAIL DEPOSIT] Showing "Bayar Sekarang" FAB');
      return FloatingActionButton.extended(
        backgroundColor: Theme.of(context).primaryColor,
        icon: Icon(Icons.navigate_next),
        label: Text('Bayar Sekarang'),
        onPressed: () {
          print('🔍 [DETAIL DEPOSIT] "Bayar Sekarang" button pressed');
          print('🔍 [DETAIL DEPOSIT] Navigating to TransferDepositPage with nominal: ${widget.dep.nominal}, type: ${widget.dep.type}');
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  TransferDepositPage(widget.dep.nominal, widget.dep.type)));
        },
      );
    } else if (widget.dep.statusModel.status == 0 &&
        (widget.dep.type == 5 ||
            widget.dep.vaname == 'alfamart' ||
            widget.dep.vaname == 'indomaret')) {
      print('🔍 [DETAIL DEPOSIT] Showing "Salin Kode Pembayaran" FAB');
      return FloatingActionButton.extended(
        backgroundColor: Theme.of(context).primaryColor,
        label: Text('Salin Kode Pembayaran'),
        icon: Icon(Icons.content_copy),
        onPressed: () async {
          print('🔍 [DETAIL DEPOSIT] "Salin Kode Pembayaran" button pressed');
          print('🔍 [DETAIL DEPOSIT] Payment code: ${widget.dep.kodePembayaran}');
          await Clipboard.setData(
              ClipboardData(text: widget.dep.kodePembayaran));
          print('🔍 [DETAIL DEPOSIT] Payment code copied to clipboard');
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Kode pembayaran berhasil disalin")));
        },
      );
    } else {
      print('🔍 [DETAIL DEPOSIT] No FAB needed for this deposit state');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    print('🔍 [DETAIL DEPOSIT] initState called');
    print('🔍 [DETAIL DEPOSIT] Deposit ID: ${widget.dep.id}');
    print('🔍 [DETAIL DEPOSIT] Deposit nominal: ${widget.dep.nominal}');
    print('🔍 [DETAIL DEPOSIT] Deposit status: ${widget.dep.statusModel.statusText}');
    print('🔍 [DETAIL DEPOSIT] User ID: ${bloc.userId.valueWrapper?.value}');
    
    var analyticsData = {
      'userId': bloc.userId.valueWrapper?.value,
      'title': 'Detail Deposit',
    };
    print('🔍 [DETAIL DEPOSIT] Analytics payload: ${analyticsData.toString()}');
    analitycs.pageView('/deposit/detail/' + widget.dep.id, analyticsData);
    print('🔍 [DETAIL DEPOSIT] Analytics page view sent');
  }

  Widget build(BuildContext context) {
    print('🔍 [DETAIL DEPOSIT] build() called');
    print('🔍 [DETAIL DEPOSIT] Building detail deposit UI for deposit: ${widget.dep.id}');
    
    return Scaffold(
        appBar: AppBar(
          title: Text('Detail Deposit'),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.home_rounded),
              onPressed: () {
                print('🔍 [DETAIL DEPOSIT] Home button pressed');
                print('🔍 [DETAIL DEPOSIT] Navigating to home page');
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) =>
                          configAppBloc.layoutApp?.valueWrapper?.value['home'] ??
                          templateConfig[
                              configAppBloc.templateCode.valueWrapper?.value],
                    ),
                    (route) => false);
              },
            ),
          ],
        ),
        body: Column(children: <Widget>[
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height / 5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).canvasColor
                  ],
                  begin: AlignmentDirectional.topCenter,
                  end: AlignmentDirectional.bottomCenter),
            ),
            child: Center(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(formatRupiah(widget.dep.nominal),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text(formatDate(widget.dep.created_at, 'd MMMM yyyy HH:mm:ss'),
                    style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold))
              ],
            )),
          ),
          Flexible(
              flex: 1,
              child: ListView(padding: EdgeInsets.all(15), children: <Widget>[
                SizedBox(height: 20.0),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(.1),
                            offset: Offset(5, 10),
                            blurRadius: 20)
                      ]),
                  child: Column(
                      // crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text('Informasi Deposit',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor)),
                            Icon(
                              Icons.info,
                              color: Theme.of(context).primaryColor,
                            )
                          ],
                        ),
                        Divider(),
                        SizedBox(height: 15),
                        widget.dep.type == 8
                            ? QrImageView(
                                data: widget.dep.kodePembayaran,
                                backgroundColor: Theme.of(context).canvasColor,
                                foregroundColor: Theme.of(context).primaryColor,
                                gapless: true,
                                size: MediaQuery.of(context).size.width * .70,
                                version: QrVersions.auto)
                            : widget.dep.kodePembayaran.isNotEmpty
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Text('Kode Pembayaran',
                                                style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 11)),
                                            Text(widget.dep.kodePembayaran,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green))
                                          ],
                                        ),
                                        SizedBox(height: 10),
                                      ])
                                : SizedBox(),
                        widget.dep.vaname.isNotEmpty
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Text('Metode',
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 11)),
                                        Text(widget.dep.vaname.toUpperCase(),
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold))
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                  ])
                            : SizedBox(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text('Nominal',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 11)),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(
                                        text: widget.dep.nominal.toString()))
                                    .then((_) {
                                  showToast(
                                      context, 'Berhasil menyalin nominal');
                                });
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(formatRupiah(widget.dep.nominal),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  SizedBox(width: 7),
                                  Icon(
                                    Icons.copy_rounded,
                                    size: 17,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text('Biaya Admin',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 11)),
                            Text(formatRupiah(widget.dep.admin),
                                style: TextStyle(fontWeight: FontWeight.bold))
                          ],
                        ),
                        SizedBox(height: 10),
                        widget.dep.keterangan != ''
                            ? Column(
                                children: <Widget>[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Text('Keterangan',
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 11)),
                                      Flexible(
                                        flex: 1,
                                        child: Text(widget.dep.keterangan,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      )
                                    ],
                                  ),
                                  SizedBox(height: 10)
                                ],
                              )
                            : SizedBox(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text('Waktu Deposit',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 11)),
                            Text(
                                formatDate(widget.dep.created_at,
                                    'd MMMM yyyy HH:mm:ss'),
                                style: TextStyle(fontWeight: FontWeight.bold))
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text('Waktu Kadaluarsa',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 11)),
                            Text(
                                formatDate(widget.dep.expired_at,
                                    'd MMMM yyyy HH:mm:ss'),
                                style: TextStyle(fontWeight: FontWeight.bold))
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text('Status',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 11)),
                            Text(
                                widget.dep.statusModel.statusText.toUpperCase(),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: widget.dep.statusModel.color))
                          ],
                        ),
                      ]),
                ),
                SizedBox(height: 15),
                widget.dep.type == 5
                    ? Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10.0),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(.1),
                                  offset: Offset(5, 10),
                                  blurRadius: 20)
                            ]),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: <
                                Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text('Informasi Rekening',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor)),
                              Icon(
                                Icons.info,
                                color: Theme.of(context).primaryColor,
                              )
                            ],
                          ),
                          Divider(),
                          SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text('Kode Pembayaran',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 11)),
                              Text(widget.dep.kodePembayaran,
                                  style: TextStyle(fontWeight: FontWeight.bold))
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text('Nama Pengguna',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 11)),
                              Text(widget.dep.nama,
                                  style: TextStyle(fontWeight: FontWeight.bold))
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text('Nama Akun Virtual',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 11)),
                              Text(widget.dep.vaname,
                                  style: TextStyle(fontWeight: FontWeight.bold))
                            ],
                          )
                        ]))
                    : Container(),
              ]))
        ]),
        floatingActionButton: fab());
  }
}

abstract class DetailDepositController extends State<DetailDeposit>
    with TickerProviderStateMixin {}

// @dart=2.9

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/Products/alpay/layout/components/template.dart';
import 'package:mobile/bloc/Bloc.dart';
import 'package:mobile/models/deposit.dart';
import 'package:mobile/modules.dart';
import 'package:mobile/provider/analitycs.dart';
import 'package:mobile/screen/topup/bank/transfer-deposit.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share/share.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailDeposit extends StatefulWidget {
  final DepositModel dep;
  DetailDeposit(this.dep);

  @override
  _DetailDepositState createState() => _DetailDepositState();
}

class _DetailDepositState extends State<DetailDeposit> {
  ScreenshotController _screenshotController = ScreenshotController();
  File image;
  bool danaApp = false;

  @override
  void initState() {
    super.initState();
    analitycs.pageView(
        '/deposit/' + widget.dep.type.toString() + '/' + widget.dep.id,
        {'userId': bloc.userId.valueWrapper?.value, 'title': 'Detail Deposit'});
    checkingDanaApp();
  }

  void checkingDanaApp() async {
    // For now, set danaApp to false since we can't check installed apps
    // This can be implemented later with proper package or alternative method
    setState(() {
      danaApp = false;
    });
  }

  Widget fab() {
    if (widget.dep.statusModel.status == 0 &&
        (widget.dep.type == 1 || widget.dep.type == 2)) {
      return FloatingActionButton.extended(
        backgroundColor: Theme.of(context).primaryColor,
        icon: Icon(Icons.navigate_next),
        label: Text('Bayar Sekarang'),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) =>
                TransferDepositPage(widget.dep.nominal, widget.dep.type))),
      );
    } else if (widget.dep.statusModel.status == 0 &&
        (widget.dep.type == 5 ||
            widget.dep.vaname == 'alfamart' ||
            widget.dep.vaname == 'indomaret')) {
      return FloatingActionButton.extended(
        backgroundColor: Theme.of(context).primaryColor,
        label: Text('Salin Kode Pembayaran'),
        icon: Icon(Icons.content_copy),
        onPressed: () async {
          await Clipboard.setData(
              ClipboardData(text: widget.dep.kodePembayaran));
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Kode pembayaran berhasil disalin")));
        },
      );
    } else {
      return null;
    }
  }

  void bayarDana() async {
    Directory temp = await getTemporaryDirectory();
    image = await File('${temp.path}/qr.png').create();
    Uint8List bytes = await _screenshotController.capture(pixelRatio: 2.5);
    await image.writeAsBytes(bytes);
    if (image == null) return;
    print(image.path);
    await Share.shareFiles(
      [image.path],
      text: 'Bayar Pakai Dana',
      packageApp: 'id.dana',
    );
  }

  @override
  Widget build(BuildContext context) {
    String methode = 'Bank';
    if (widget.dep.type == 1) {
      methode = 'Bank Transfer';
    } else if (widget.dep.type == 2) {
      methode = 'Ewallet Transfer';
    } else if (widget.dep.type == 5 || widget.dep.type == 6) {
      methode = 'Agen ${widget.dep.vaname}';
    } else if (widget.dep.type == 9) {
      methode = 'QRIS Static';
    } else if (widget.dep.type == 8) {
      methode = 'Qris';
    }
    print(widget.dep.type);
    print(methode);

    return TemplatePayuni2(
      title: 'Detail Deposit',
      height: 300.0,
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(top: 40.0, left: 10, right: 10, bottom: 20.0),
          padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    blurRadius: 10.0,
                    color: Colors.black.withOpacity(.1),
                    offset: Offset(5, 5))
              ]),
          child: ListView(
            shrinkWrap: true,
            physics: ScrollPhysics(),
            children: <Widget>[
              CachedNetworkImage(
                  imageUrl:
                      'https://dokumen.payuni.co.id/logo/ualreload/deposit.png',
                  width: 100.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                      formatDate(widget.dep.created_at, 'd MMMM yyyy HH:mm:ss'),
                      style: TextStyle(color: Colors.grey[600])),
                  Text(
                      widget.dep.status == 0
                          ? 'Menunggu Pembayaran'
                          : widget.dep.status == 1
                              ? 'Topup Berhasil'
                              : 'Topup Gagal',
                      style: TextStyle(
                          color: widget.dep.status == 0
                              ? Colors.yellow[700]
                              : widget.dep.status == 1
                                  ? Colors.green[400]
                                  : Colors.red[400]))
                ],
              ),
              Divider(),
              SizedBox(height: 20.0),
              widget.dep.type == 8
                  ? Column(
                      children: <Widget>[
                        SizedBox(height: 10.0),
                        Screenshot(
                          controller: _screenshotController,
                          child: QrImageView(
                            data: widget.dep.kodePembayaran,
                            backgroundColor: Theme.of(context).canvasColor,
                            foregroundColor: Colors.black,
                            gapless: true,
                            size: MediaQuery.of(context).size.width * .50,
                            version: QrVersions.auto,
                          ),
                        ),
                        Text('Scan QR Code Ini Untuk Melakukan Pembayaran'),
                        SizedBox(height: 20.0),
                        widget.dep.status == 0 && danaApp
                            ? InkWell(
                                onTap: bayarDana,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 20.0,
                                  ),
                                  decoration: BoxDecoration(color: Colors.blue),
                                  child: Text(
                                    'Bayar Pakai Dana',
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            : Container(),
                        SizedBox(height: 20.0),
                      ],
                    )
                  : widget.dep.kodePembayaran.isNotEmpty
                      ? Column(
                          children: <Widget>[
                            Text('Kode Pembayaran',
                                style: TextStyle(color: Colors.grey[700])),
                            SizedBox(height: 10.0),
                            Text(widget.dep.kodePembayaran,
                                style: TextStyle(fontSize: 20.0)),
                            TextButton.icon(
                                onPressed: () {},
                                icon: Icon(Icons.content_copy, size: 16.0),
                                label: Text('Salin Kode',
                                    style: TextStyle(fontSize: 10.0))),
                          ],
                        )
                      : SizedBox(),
              SizedBox(height: 10.0),
              Text('Informasi Deposit',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('Methode Pembayaran'),
                  Text(methode,
                      style: TextStyle(color: Theme.of(context).primaryColor))
                ],
              ),
              SizedBox(height: 10.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('Nominal'),
                  Text(formatRupiah(widget.dep.nominal),
                      style: TextStyle(color: Theme.of(context).primaryColor))
                ],
              ),
              SizedBox(height: 10.0),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('Admin'),
                  Text(formatRupiah(widget.dep.admin),
                      style: TextStyle(color: Theme.of(context).primaryColor))
                ],
              ),
              SizedBox(height: 10.0),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                color: Colors.grey[100],
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text('Total Bayar'),
                    Text(formatRupiah(widget.dep.admin + widget.dep.nominal),
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold))
                  ],
                ),
              ),
              SizedBox(height: 20),
              widget.dep.keterangan != ''
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text('Keterangan'),
                        Flexible(
                          flex: 1,
                          child: Text(widget.dep.keterangan),
                        )
                      ],
                    )
                  : SizedBox(),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('Waktu Kadaluarsa'),
                  Text(
                      formatDate(widget.dep.expired_at, 'd MMMM yyyy HH:mm:ss'))
                ],
              ),
              SizedBox(height: 10.0),
              ((widget.dep.type == 1 || widget.dep.type == 2) &&
                      widget.dep.status == 0)
                  ? ElevatedButton(
                      style: ButtonStyle(
                        elevation: MaterialStateProperty.all(0),
                        backgroundColor: MaterialStateProperty.all(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => TransferDepositPage(
                                  widget.dep.nominal, widget.dep.type))),
                      child: Text(
                        'Bayar Sekarang',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : SizedBox(),
              SizedBox(height: 20.0)
            ],
          ),
        ),
      ),
    );
  }
}

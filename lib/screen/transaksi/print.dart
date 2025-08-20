// @dart=2.9

import 'dart:convert';
import 'dart:io';
import 'dart:io' show Platform;

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/bloc/Api.dart';
import 'package:mobile/bloc/Bloc.dart' show bloc;
import 'package:http/http.dart' as http;
import 'package:mobile/bloc/ConfigApp.dart';
import 'package:mobile/bloc/TemplateConfig.dart';
import 'package:mobile/config.dart';
import 'package:mobile/models/trx.dart';
import 'package:mobile/modules.dart';
import 'package:mobile/provider/analitycs.dart';
import 'package:mobile/screen/custom_alert_dialog.dart';
import 'package:mobile/screen/transaksi/select_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'test_bluetooth_ios.dart';
import 'network_test.dart';
import 'network_printer_complete.dart';

class PrintPreview extends StatefulWidget {
  final TrxModel trx;
  final bool isPostpaid;

  PrintPreview({Key key, this.trx, this.isPostpaid = false}) : super(key: key) {
    print("isPostpaid in constructor: $isPostpaid");
  }

  @override
  _PrintPreviewState createState() => _PrintPreviewState();
}

class _PrintPreviewState extends PrintPreviewController {
  BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  ScreenshotController _screenshotController = ScreenshotController();
  File image;
  bool isLogoPrinter = false;
  String footerStruk =
      'TERSEDIA PULSA, KUOTA ALL OPERATOR, TOKEN PLN, BAYAR TAGIHAN LISTRIK, PDAM, TELKOM, ITEM GAME, DAN MULTI PEMBAYARAN LAINNYA';

  Future<void> share() async {
    Directory temp = await getTemporaryDirectory();
    image = await File('${temp.path}/trx_${widget.trx.id}.png').create();
    Uint8List bytes = await _screenshotController.capture(
      pixelRatio: 2.5,
      delay: Duration(milliseconds: 100),
    );
    await image.writeAsBytes(bytes);
    if (image == null) return;
    await Share.file(
      'Transaksi ${widget.trx.produk['nama']}',
      'trx_${widget.trx.id}.png',
      image.readAsBytesSync(),
      'image/png',
    );
  }

  Future<void> simpanEditHarga() async {
    String productId = widget.trx.produk['_id'];
    print(productId);
    String hargaJual = widget.isPostpaid ? '0' : txtHarga.text;
    try {
      http.Response response =
          await http.post(Uri.parse('$apiUrl/product/member/$productId'),
              headers: {
                'Authorization': bloc.token.valueWrapper?.value,
                'Content-Type': 'application/json'
              },
              body: json.encode({
                'harga': hargaJual,
                'admin': txtAdmin.text,
              }));
      print(response.body);
      String message = json.decode(response.body)['message'];
      if (response.statusCode == 200) {
        showCustomDialog(
            context: context,
            type: DialogType.success,
            title: 'Berhasil',
            content: 'Edit Data Berhasil.',
            onConfirmed: () {
              setState(() {
                showEditor = false;
              });
            });
      } else {
        String message = json.decode(response.body)['message'];
        showCustomDialog(
          context: context,
          type: DialogType.error,
          title: 'Gagal',
          content: message,
        );
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  void initState() {
    setState(() {
      trxData = widget.trx;
    });
    getData();
    analitycs.pageView('/transaksi/' + widget.trx.id + '/print',
        {'userId': bloc.userId.valueWrapper.value, 'title': 'Print Transaksi'});
    harga = trxData.harga_jual;
    total = harga + admin;
    txtHarga.text = harga.toString();
    txtAdmin.text = admin.toString();

    List packageList = [
      'ayoba.co.id',
    ];

    packageList.forEach((element) {
      if (element == packageName) {
        setState(() {
          isLogoPrinter = true;
        });
      }
    });

    if (dynamicFooterStruk) {
      if (configAppBloc.info.valueWrapper.value.footerStruk.isNotEmpty) {
        setState(() {
          footerStruk = configAppBloc.info.valueWrapper.value.footerStruk;
        });
      }
    }

    super.initState();
  }

  Widget snWidget() {
    if (showSN) {
      if (trxData.print.length == 0) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('SN',
                style: TextStyle(
                  fontFamily: 'Poppins',
                )),
            SizedBox(width: 5),
            Flexible(
              flex: 1,
              child: Text(
                trxData.sn,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontFamily: 'Poppins',
                ),
              ),
            )
          ],
        );
      } else {
        return SizedBox();
      }
    } else {
      if (trxData.print
              .where((el) => el['label'].toString().toLowerCase() == 'token')
              .length >
          0) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Divider(thickness: 3),
            Text(
              trxData.print
                  .where(
                      (el) => el['label'].toString().toLowerCase() == 'token')
                  .first['value'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        );
      } else {
        return SizedBox();
      }
    }
  }

  Uint8List v1(PaperSize paperSize, CapabilityProfile profile) {
    Generator ticket = Generator(paperSize, profile);
    List<int> bytes = [];
    ticket.setGlobalFont(PosFontType.fontA);
    int i = bloc.printerFontSize.valueWrapper.value - 1;
    List<PosTextSize> sizes = [
      PosTextSize.size1,
      PosTextSize.size2,
      PosTextSize.size3,
      PosTextSize.size4,
      PosTextSize.size5,
      PosTextSize.size6,
      PosTextSize.size7,
      PosTextSize.size8,
    ];

    bytes += ticket.emptyLines(1);
    bytes += ticket.text(
      bloc.user.valueWrapper.value.namaToko.isEmpty
          ? bloc.user.valueWrapper.value.nama
          : bloc.user.valueWrapper.value.namaToko,
      styles: PosStyles(
        width: sizes[i + 1],
        height: sizes[i + 1],
        bold: true,
        align: PosAlign.center,
      ),
    );
    bytes += ticket.text(
      bloc.user.valueWrapper.value.alamatToko.isEmpty
          ? bloc.user.valueWrapper.value.alamat
          : bloc.user.valueWrapper.value.alamatToko,
      styles: PosStyles(
        align: PosAlign.center,
        width: sizes[i],
        height: sizes[i],
      ),
      linesAfter: 1,
    );
    bytes += ticket.text(
      formatDate(trxData.created_at, 'dd MMMM yyyy HH:mm:ss'),
      styles: PosStyles(
        width: sizes[i],
        height: sizes[i],
      ),
    );
    bytes += ticket.text(
      'TrxID: ${trxData.id.toUpperCase()}',
      styles: PosStyles(
        width: sizes[i],
        height: sizes[i],
      ),
    );
    bytes += ticket.hr();
    bytes += ticket.text(
      'Transaksi:',
      styles: PosStyles(
        underline: true,
        width: sizes[i],
        height: sizes[i],
      ),
    );
    bytes += printLine(ticket, [
      {
        'label': 'Nama Produk',
        'value': trxData.produk['nama'],
      },
      {
        'label': 'Tujuan',
        'value': trxData.tujuan,
      },
    ]);
    if (showDefaultTagihan) {
      bytes += printLine(ticket, [
        {
          'label': labelHarga,
          'value': formatRupiah(harga),
        },
      ]);
    }
    if (showDefaultAdmin) {
      bytes += printLine(ticket, [
        {
          'label': 'Admin',
          'value': formatRupiah(admin),
        },
      ]);
    }
    trxData.print.forEach((el) {
      if (!['token', 'jumlah', 'nominal', 'tagihan', 'admin']
          .contains(el['label'].toString().toLowerCase())) {
        bytes += printLine(ticket, [
          {
            'label': el['label'],
            'value': el['value'],
          },
        ]);
      }
    });
    if (showSN) {
      if (trxData.print.isEmpty) {
        bytes += printLine(ticket, [
          {
            'label': 'SN',
            'value': trxData.sn,
          },
        ]);
      }
    } else {
      bytes += ticket.hr();
      trxData.print.forEach((el) {
        if (el['label'].toString().toLowerCase() == 'token') {
          bytes += ticket.text(
            el['value'].toString(),
            styles: PosStyles(
              bold: true,
              align: PosAlign.center,
              width: sizes[i + 1],
              height: sizes[i + 1],
            ),
          );
        }
      });
    }
    bytes += ticket.hr();
    bytes += printLine(
      ticket,
      [
        {
          'label': 'Total',
          'value': formatRupiah(total),
        }
      ],
      bold: true,
    );
    bytes += ticket.hr(linesAfter: 1);
    bytes += ticket.text(
      'STRUK INI MERUPAKAN BUKTI PEMBAYARAN YANG SAH',
      styles: PosStyles(
        align: PosAlign.center,
        width: sizes[i],
        height: sizes[i],
      ),
      linesAfter: 1,
    );
    bytes += ticket.text(
      footerStruk,
      styles: PosStyles(
        align: PosAlign.center,
        width: sizes[i],
        height: sizes[i],
      ),
      linesAfter: 3,
    );

    return Uint8List.fromList(bytes);
  }

  Future<void> v2() async {
    await _bluetooth.printNewLine();
    await _bluetooth.printCustom(
      bloc.user.valueWrapper.value.namaToko.isEmpty
          ? bloc.user.valueWrapper.value.nama
          : bloc.user.valueWrapper.value.namaToko,
      2,
      1,
    );
    await _bluetooth.printCustom(
      bloc.user.valueWrapper.value.alamatToko.isEmpty
          ? bloc.user.valueWrapper.value.alamat
          : bloc.user.valueWrapper.value.alamatToko,
      0,
      1,
    );
    await _bluetooth.printNewLine();
    await _bluetooth.printCustom(
        formatDate(trxData.created_at, 'dd MMMM yyyy HH:mm:ss'), 0, 0);
    await _bluetooth.printCustom('TrxID: ${trxData.id.toUpperCase()}', 0, 0);
    await _bluetooth.printCustom('------------------', 0, 1);
    await _bluetooth.printCustom('Transaksi:', 0, 0);
    await _bluetooth.printLeftRight('Nama Produk', trxData.produk['nama'], 0);
    await _bluetooth.printLeftRight('Tujuan', trxData.tujuan, 0);
    if (showDefaultTagihan) {
      await _bluetooth.printLeftRight(labelHarga, formatRupiah(harga), 0);
    }
    if (showDefaultAdmin) {
      await _bluetooth.printLeftRight('Admin', formatRupiah(admin), 0);
    }
    if (packageName == 'com.funmo.id') {
      await _bluetooth.printLeftRight('Cetak', formatRupiah(cetak), 0);
    }
    trxData.print.forEach((el) async {
      if (!['token', 'jumlah', 'nominal', 'tagihan', 'admin']
          .contains(el['label'].toString().toLowerCase())) {
        await _bluetooth.printLeftRight(el['label'], el['value'], 0);
      }
    });
    if (showSN) {
      if (trxData.print.length == 0) {
        await _bluetooth.printLeftRight('SN', trxData.sn, 0);
      }
    } else {
      await _bluetooth.printCustom('------------------', 0, 1);
      trxData.print.forEach((el) async {
        print('tes');
        if (el['label'].toString().toLowerCase() == 'token') {
          await _bluetooth.printCustom(el['value'], 1, 1);
        }
      });
    }
    await _bluetooth.printCustom('------------------', 0, 1);
    await _bluetooth.printLeftRight('Total', formatRupiah(total), 1);
    await _bluetooth.printCustom('------------------', 0, 1);
    await _bluetooth.printNewLine();
    await _bluetooth.printCustom(
        'STRUK INI MERUPAKAN BUKTI PEMBAYARAN YANG SAH', 0, 1);
    await _bluetooth.printNewLine();
    await _bluetooth.printCustom(
      footerStruk,
      0,
      1,
    );
    await _bluetooth.printNewLine();
    await _bluetooth.printNewLine();
    await _bluetooth.printNewLine();
  }

  Future<bool> checkBluetooth() async {
    // Request multiple permissions for iOS
    Map<Permission, PermissionStatus> statuses = await [
      Permission.locationWhenInUse,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();
    
    bool isOn = await _bluetooth.isOn;
    
    // Check if any of the required permissions are granted
    bool hasLocationPermission = statuses[Permission.locationWhenInUse] == PermissionStatus.granted;
    bool hasBluetoothPermission = statuses[Permission.bluetooth] == PermissionStatus.granted;
    bool hasBluetoothConnectPermission = statuses[Permission.bluetoothConnect] == PermissionStatus.granted;
    bool hasBluetoothScanPermission = statuses[Permission.bluetoothScan] == PermissionStatus.granted;
    
    // For iOS, we need at least location permission and bluetooth permissions
    bool hasRequiredPermissions = hasLocationPermission && 
                                 (hasBluetoothPermission || hasBluetoothConnectPermission || hasBluetoothScanPermission);

    if (hasRequiredPermissions) {
      if (isOn) {
        return true;
      } else {
        showToast(context, 'Bluetooth belum aktif. Silakan aktifkan Bluetooth di pengaturan.');
        return false;
      }
    } else {
      showToast(context, 'Aplikasi memerlukan izin lokasi dan bluetooth untuk menemukan printer');
      return false;
    }
  }

  // static const platform = MethodChannel('com.findig.bluetooth_settings');

  // Future<bool> checkBluetooth() async {
  //   var isCheck = await _bluetooth.isOn;
  //   if (!isCheck) {
  //     showDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (_) => AlertDialog(
  //         title: Text('Warning'),
  //         content: Text('Bluetooth kamu belum aktif, silahkan aktifkan terlebih dahulu.'),
  //         actions: [
  //           // ignore: deprecated_member_use
  //           TextButton(
  //             child: Text('Aktifkan'),
  //             onPressed: () async {
  //               if (Platform.isAndroid) {
  //                 if (await openBluetoothSettings()) {
  //                   Navigator.of(context, rootNavigator: true).pop();
  //                 }
  //               }
  //             }
  //           ),
  //           // ignore: deprecated_member_use
  //           TextButton(
  //             child: Text('Batal'),
  //             onPressed: () {
  //               Navigator.of(context, rootNavigator: true).pop();
  //             }
  //           ),
  //         ],
  //       ),
  //     );
  //     return false;
  //   }
  //   return true;
  // }

  // Future<bool> openBluetoothSettings() async {
  //   try {
  //     if (Platform.isAndroid) {
  //       if (await Permission.location.request().isGranted &&
  //           await Permission.bluetoothConnect.request().isGranted) {
  //         final bool result = await platform.invokeMethod('openBluetoothSettings');
  //         return result;
  //       }
  //     }
  //     return false;
  //   } on PlatformException catch (e) {
  //     print("Failed to open Bluetooth settings: '${e.message}'.");
  //     return false;
  //   }
  // }

  Future<void> startPrint() async {
    bool status = await checkBluetooth();
    if (!status) return;

    // Add debugging for iOS
    print("Bluetooth status: $status");
    print("Platform: ${Platform.operatingSystem}");
    
    BluetoothDevice device;
    try {
      device = await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => SelectPrinterPage()));
      if (device == null) {
        print("No device selected");
        return;
      }
      
      print("Selected device: ${device.name} (${device.address})");
    } catch (e) {
      print("Error selecting printer: $e");
      showToast(context, 'Gagal memilih printer: $e');
      return;
    }

    if (await _bluetooth.isConnected) await _bluetooth.disconnect();
    await _bluetooth.connect(device);
    final _profile = await CapabilityProfile.load();

    try {
      switch (bloc.printerType.valueWrapper.value) {
        case 1:
          Uint8List bytes = v1(PaperSize.mm58, _profile);
          int totalChunks = (bytes.length - (bytes.length % 100)) ~/ 100;
          for (int i = 0; i < totalChunks; i++) {
            if (i == totalChunks - 1) {
              await _bluetooth.writeBytes(bytes.sublist(i * 100));
            } else {
              await _bluetooth
                  .writeBytes(bytes.sublist(i * 100, (i + 1) * 100));
            }
            await Future.delayed(Duration(milliseconds: 200));
          }
          break;
        case 2:
          Uint8List bytes = v1(PaperSize.mm80, _profile);
          int totalChunks = (bytes.length - (bytes.length % 100)) ~/ 100;
          for (int i = 0; i < totalChunks; i++) {
            if (i == totalChunks - 1) {
              await _bluetooth.writeBytes(bytes.sublist(i * 100));
            } else {
              await _bluetooth
                  .writeBytes(bytes.sublist(i * 100, (i + 1) * 100));
            }
            await Future.delayed(Duration(milliseconds: 200));
          }
          break;
        case 3:
          await v2();
          break;
        default:
          await _bluetooth.writeBytes(v1(PaperSize.mm58, _profile));
      }
      showToast(context, 'Berhasil mencetak struk');
    } catch (_) {
      showToast(context, 'Gagal mencetak struk');
    } finally {
      await _bluetooth.disconnect();
    }
  }

  @override
  Widget build(BuildContext context) {
    print("isPostpaid: ${widget.isPostpaid}");
    return Scaffold(
      appBar: AppBar(
        title: Text('Cetak'),
        centerTitle: true,
        backgroundColor: packageName == 'com.lariz.mobile'
            ? Theme.of(context).secondaryHeaderColor
            : Theme.of(context).primaryColor,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.home_rounded),
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) =>
                      configAppBloc.layoutApp?.valueWrapper.value['home'] ??
                      templateConfig[
                          configAppBloc.templateCode.valueWrapper.value],
                ),
                (route) => false),
          ),
          IconButton(
            icon: Icon(Icons.share_rounded),
            onPressed: share,
          ),
          IconButton(
            icon: Icon(Icons.edit_rounded),
            onPressed: () {
              setState(() {
                showEditor = !showEditor;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.bluetooth),
            onPressed: () {
              // Navigate to Bluetooth test page
              Navigator.push(context, MaterialPageRoute(builder: (_) => BluetoothTestPage()));
            },
          ),
          IconButton(
            icon: Icon(Icons.wifi),
            onPressed: () {
              // Navigate to Network printer test page
              Navigator.push(context, MaterialPageRoute(builder: (_) => NetworkTestPage()));
            },
          ),
        ],
      ),
      body: Container(
        margin: EdgeInsets.all(15),
        child: Column(children: <Widget>[
          !showEditor
              ? SizedBox(width: 0, height: 0)
              : Container(
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
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        packageName == 'com.eralink.mobileapk' ||
                                packageName == 'com.lariz.mobile'
                            ? TextFormField(
                                controller: txtHarga,
                                keyboardType: TextInputType.number,
                                cursorColor: Theme.of(context).primaryColor,
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                      color: packageName == 'com.lariz.mobile'
                                          ? Theme.of(context)
                                              .secondaryHeaderColor
                                          : Theme.of(context).primaryColor,
                                    )),
                                    focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                      color: packageName == 'com.lariz.mobile'
                                          ? Theme.of(context)
                                              .secondaryHeaderColor
                                          : Theme.of(context).primaryColor,
                                    )),
                                    labelText: labelHarga,
                                    labelStyle: TextStyle(
                                        color: Theme.of(context)
                                            .secondaryHeaderColor),
                                    prefixText: 'Rp ',
                                    prefixStyle: TextStyle(
                                        color: Theme.of(context)
                                            .secondaryHeaderColor)),
                                onChanged: (value) => setState(() {
                                      if (value == null) {
                                        harga = 0;
                                        total = 0 + admin + cetak;
                                      } else {
                                        harga = int.parse(value);
                                        total = harga + admin + cetak;
                                      }
                                    }))
                            : TextFormField(
                                controller: txtHarga,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: labelHarga,
                                    prefixText: 'Rp '),
                                onChanged: (value) => setState(() {
                                      if (value == null) {
                                        harga = 0;
                                        total = 0 + admin + cetak;
                                      } else {
                                        harga = int.parse(value);
                                        total = harga + admin + cetak;
                                      }
                                    })),
                        SizedBox(height: 10),
                        packageName == 'com.eralink.mobileapk' ||
                                packageName == 'com.lariz.mobile'
                            ? TextFormField(
                                controller: txtAdmin,
                                keyboardType: TextInputType.number,
                                cursorColor: Theme.of(context).primaryColor,
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                      color: packageName == 'com.lariz.mobile'
                                          ? Theme.of(context)
                                              .secondaryHeaderColor
                                          : Theme.of(context).primaryColor,
                                    )),
                                    focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                      color: packageName == 'com.lariz.mobile'
                                          ? Theme.of(context)
                                              .secondaryHeaderColor
                                          : Theme.of(context).primaryColor,
                                    )),
                                    labelText: 'Admin',
                                    labelStyle: TextStyle(
                                        color: Theme.of(context)
                                            .secondaryHeaderColor),
                                    prefixText: 'Rp ',
                                    prefixStyle: TextStyle(
                                        color: Theme.of(context)
                                            .secondaryHeaderColor)),
                                onChanged: (value) => setState(() {
                                      if (value == null) {
                                        admin = 0;
                                        total = harga + 0 + cetak;
                                      } else {
                                        admin = int.parse(value);
                                        total = harga + admin + cetak;
                                      }
                                    }))
                            : TextFormField(
                                controller: txtAdmin,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Admin',
                                    prefixText: 'Rp '),
                                onChanged: (value) => setState(() {
                                      if (value == null) {
                                        admin = 0;
                                        total = harga + 0 + cetak;
                                      } else {
                                        admin = int.parse(value);
                                        total = harga + admin + cetak;
                                      }
                                    })),
                        SizedBox(
                            height: packageName == "com.funmo.id" ? 10 : 0),
                        packageName == "com.funmo.id"
                            ? TextFormField(
                                controller: txtCetak,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Biaya Cetak',
                                    prefixText: 'Rp '),
                                onChanged: (value) => setState(() {
                                      if (value == null) {
                                        cetak = 0;
                                        total = harga + admin + 0;
                                      } else {
                                        cetak = int.parse(value);
                                        total = harga + admin + cetak;
                                      }
                                    }))
                            : SizedBox(),
                        SizedBox(height: 10),
                        ButtonTheme(
                          minWidth: double.infinity,
                          height: 40,
                          child: MaterialButton(
                            color: packageName == 'com.lariz.mobile'
                                ? Theme.of(context).secondaryHeaderColor
                                : Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Simpan'.toUpperCase(),
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: simpanEditHarga,
                          ),
                        ),
                      ]),
                ),
          SizedBox(height: showEditor ? 15 : 0),
          Flexible(
            flex: 1,
            child: ListView(
              children: <Widget>[
                Screenshot(
                  controller: _screenshotController,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        image: configAppBloc.iconApp.valueWrapper
                                    .value['backgroundStruk'] ==
                                null
                            ? null
                            : DecorationImage(
                                image: CachedNetworkImageProvider(configAppBloc
                                    .iconApp
                                    .valueWrapper
                                    .value['backgroundStruk']),
                                repeat: ImageRepeat.repeat,
                                fit: BoxFit.scaleDown,
                              ),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.85),
                          borderRadius: BorderRadius.circular(10.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.1),
                              offset: Offset(5, 10),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            isLogoPrinter
                                ? Stack(
                                    children: [
                                      configAppBloc.iconApp.valueWrapper
                                                  .value['logoPrinter'] ==
                                              null
                                          ? SizedBox()
                                          : Container(
                                              child: CachedNetworkImage(
                                                imageUrl: configAppBloc
                                                    .iconApp
                                                    .valueWrapper
                                                    .value['logoPrinter'],
                                                height: 30,
                                              ),
                                            ),
                                      Align(
                                        alignment: Alignment.topCenter,
                                        child: Container(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                  bloc.user.valueWrapper.value
                                                              .namaToko ==
                                                          ''
                                                      ? bloc.username
                                                          .valueWrapper.value
                                                      : bloc.user.valueWrapper
                                                          .value?.namaToko,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    fontFamily: 'Poppins',
                                                  )),
                                              SizedBox(height: 5),
                                              Text(
                                                  bloc.user.valueWrapper.value
                                                              .alamatToko ==
                                                          ''
                                                      ? bloc.user.valueWrapper
                                                          .value.alamat
                                                      : bloc.user.valueWrapper
                                                          .value.alamatToko,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontFamily: 'Poppins',
                                                  )),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Center(
                                    child: Column(
                                      children: [
                                        Text(
                                            bloc.user.valueWrapper.value
                                                        .namaToko ==
                                                    ''
                                                ? bloc.username.valueWrapper
                                                    ?.value
                                                : bloc.user.valueWrapper.value
                                                    .namaToko,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              fontFamily: 'Poppins',
                                            )),
                                        SizedBox(height: 5),
                                        Text(
                                            bloc.user.valueWrapper.value
                                                        .alamatToko ==
                                                    ''
                                                ? bloc.user.valueWrapper.value
                                                    .alamat
                                                : bloc.user.valueWrapper.value
                                                    .alamatToko,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'Poppins',
                                            )),
                                      ],
                                    ),
                                  ),
                            SizedBox(height: 19),
                            Text(
                              formatDate(
                                  trxData.created_at, 'd MMMM yyyy HH:mm:ss'),
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            SizedBox(height: 5),
                            Text('TrxID : ${trxData.id.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                )),
                            SizedBox(height: 10),
                            Divider(thickness: 3),
                            SizedBox(height: 10),
                            Text('Transaksi:',
                                style: TextStyle(
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                  fontFamily: 'Poppins',
                                )),
                            SizedBox(height: 10),
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(
                                    'Nama Produk',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      trxData.produk == null
                                          ? '-'
                                          : trxData.produk['nama'] ?? '-',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                      ),
                                      overflow: TextOverflow.clip,
                                      textAlign: TextAlign.end,
                                    ),
                                  )
                                ]),
                            SizedBox(height: 10),
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text('Tujuan',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                      )),
                                  Text(trxData.tujuan,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                      ))
                                ]),
                            SizedBox(height: 10),
                            showDefaultTagihan
                                ? Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                        Text(labelHarga,
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                            )),
                                        Text(formatRupiah(harga),
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                            ))
                                      ])
                                : SizedBox(),
                            SizedBox(height: showDefaultTagihan ? 10 : 0),
                            showDefaultAdmin
                                ? Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                        Text('Admin'),
                                        Text(formatRupiah(admin))
                                      ])
                                : SizedBox(),
                            SizedBox(height: showDefaultAdmin ? 10 : 0),
                            packageName == "com.funmo.id"
                                ? Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                        Text(
                                          'Biaya Cetak',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                          ),
                                        ),
                                        Text(
                                          formatRupiah(cetak),
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                          ),
                                        )
                                      ])
                                : SizedBox(),
                            SizedBox(
                                height: packageName == "com.funmo.id" ? 10 : 0),
                            ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: trxData.print.length,
                                itemBuilder: (ctx, i) {
                                  if ([
                                    'token',
                                    'jumlah',
                                    'nominal',
                                    'tagihan',
                                    'admin'
                                  ].contains(trxData.print[i]['label']
                                      .toString()
                                      .toLowerCase())) {
                                    return SizedBox();
                                  } else {
                                    return Container(
                                      margin: EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Text(
                                            trxData.print[i]['label'],
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                            ),
                                          ),
                                          Text(
                                            trxData.print[i]['value']
                                                .toString(),
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                            ),
                                          )
                                        ],
                                      ),
                                    );
                                  }
                                }),
                            snWidget(),
                            Divider(thickness: 3),
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text('Total',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins',
                                      )),
                                  Text(
                                    formatRupiah(total),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                  )
                                ]),
                            Divider(thickness: 3),
                            SizedBox(height: 10),
                            Align(
                              alignment: Alignment.topCenter,
                              child: Text(
                                'Struk ini merupakan bukti pembayaran yang sah'
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Align(
                              alignment: Alignment.center,
                              child: Text(
                                footerStruk,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                            SizedBox(height: 20.0)
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "network",
            child: Icon(Icons.wifi),
            backgroundColor: Colors.blue,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => NetworkPrinterCompletePage(trx: widget.trx, isPostpaid: widget.isPostpaid)));
            },
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "bluetooth",
            child: Icon(Icons.print),
            backgroundColor: packageName == 'com.lariz.mobile'
                ? Theme.of(context).secondaryHeaderColor
                : Theme.of(context).primaryColor,
            onPressed: startPrint,
          ),
        ],
      ),
    );
  }
}

abstract class PrintPreviewController extends State<PrintPreview>
    with TickerProviderStateMixin {
  TrxModel trxData;
  List<Map<String, dynamic>> additionalData = [];
  bool showEditor = false;
  bool showSN = false;
  bool showDefaultTagihan = true;
  bool showDefaultAdmin = true;
  int harga = 0;
  int admin = 0;
  int cetak = 0;
  int total = 0;
  String labelHarga = "Harga";

  TextEditingController txtHarga = TextEditingController();
  TextEditingController txtAdmin = TextEditingController();
  TextEditingController txtCetak = TextEditingController();

  void getData() async {
    http.Response response = await http.get(
        Uri.parse('$apiUrl/trx/${widget.trx.id}/print'),
        headers: {'Authorization': bloc.token.valueWrapper.value});

    if (response.statusCode == 200) {
      trxData = TrxModel.fromJson(json.decode(response.body)['data']);
      String kodeProduk = trxData.produk['kode_produk'];
      admin = trxData.admin;
      harga = trxData.harga_jual;
      total = harga + admin + cetak;
      txtHarga.text = harga.toString();
      txtAdmin.text = admin.toString();
      labelHarga = kodeProduk.startsWith("PLN") ? 'Nominal' : 'Harga';
      trxData.print.forEach((el) {
        if (el['label'].toString().toLowerCase() == 'admin') {
          admin = int.parse(el['value']);
          total = harga + admin + cetak;
          txtAdmin.text = admin.toString();
        }
        if (['tagihan', 'jumlah', 'nominal']
            .contains(el['label'].toString().toLowerCase())) {
          labelHarga = el['label'];
          harga = int.parse(el['value']);
          total = harga + admin + cetak;
          txtHarga.text = harga.toString();
        }
      });
      if (trxData.print
              .where((el) => el['label'].toString().toLowerCase() == 'token')
              .length ==
          0) {
        showSN = true;
      }

      setState(() {});
      print("Panggil ambilDataTerbaru");
      await ambilDataTerbaru();
    } else {
      print('Error: ${response.body}');
    }
  }

  Future<void> ambilDataTerbaru() async {
    print("Fungsi ambilDataTerbaru dipanggil");
    String productId = widget.trx.produk['_id'];
    print(productId);
    http.Response response = await http.get(
      Uri.parse('$apiUrl/product/member/$productId'),
      headers: {
        'Authorization': bloc.token.valueWrapper?.value,
      },
    );

    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      print("Full JSON Response: ${response.body}");
      int hargaBaru = responseData['data']['harga'];
      int adminBaru = responseData['data']['admin'];

      if (widget.isPostpaid && hargaBaru <= 0) {
        hargaBaru = trxData.harga_jual;
      }

      setState(() {
        harga = hargaBaru;
        admin = adminBaru;

        txtHarga.text = hargaBaru.toString();
        txtAdmin.text = adminBaru.toString();

        total = harga + admin + cetak;
      });

      print('Harga baru: $hargaBaru, Admin baru: $adminBaru');
    } else {
      print('Gagal mengambil data terbaru: ${response.body}');
    }
  }
}

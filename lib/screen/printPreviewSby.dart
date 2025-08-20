// @dart=2.9

// Export the main widget for easy importing
export 'printPreviewSby.dart' show PrintPreviewSby;

import 'dart:convert';
import 'dart:io';

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
import 'package:mobile/screen/transaksi/network_printer_complete.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';

class PrintPreviewSby extends StatefulWidget {
  final TrxModel trx;
  final bool isPostpaid;

  PrintPreviewSby({Key key, this.trx, this.isPostpaid = false}) : super(key: key) {
    print("isPostpaid in constructor: $isPostpaid");
  }

  @override
  _PrintPreviewSbyState createState() => _PrintPreviewSbyState();
}

class _PrintPreviewSbyState extends PrintPreviewSbyController {
  BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  ScreenshotController _screenshotController = ScreenshotController();
  File image;
  bool isLogoPrinter = false;
  String footerStruk =
      'TERSEDIA PULSA, KUOTA ALL OPERATOR, TOKEN PLN, BAYAR TAGIHAN LISTRIK, PDAM, TELKOM, ITEM GAME, DAN MULTI PEMBAYARAN LAINNYA';

  String _formatValue(dynamic value, {String label = ''}) {
    if (value == null) return '';
    
    // Don't format reference numbers, IDs, or specific fields
    String stringValue = value.toString();
    String lowerLabel = label.toLowerCase();
    
    // Check for reference-related labels
    if (lowerLabel.contains('reff') || 
        lowerLabel.contains('ref') || 
        lowerLabel.contains('id') ||
        lowerLabel.contains('no') ||
        lowerLabel.contains('nomor') ||
        lowerLabel.contains('kode')) {
      return stringValue;
    }
    
    // Check if the value is a number
    if (value is int || value is double) {
      return formatRupiah(value);
    }
    
    // Check if the value is a string that can be parsed as a number
    if (stringValue.contains(RegExp(r'^\d+$'))) {
      // Don't format reference numbers or IDs
      if (stringValue.length > 10) {
        return stringValue; // Likely a reference number or ID
      }
      return formatRupiah(int.parse(stringValue));
    }
    
    // Return as is if it's not a number
    return stringValue;
  }

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
    
    // Override with custom footer text if available
    if (customFooterText.isNotEmpty) {
      setState(() {
        footerStruk = customFooterText;
      });
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

  // Method to generate receipt data for network printing
  Future<Uint8List> generateReceiptData() async {
    try {
      final profile = await CapabilityProfile.load();
      return v1(PaperSize.mm58, profile);
    } catch (e) {
      print('Error generating receipt data: $e');
      throw Exception('Error generating receipt data: $e');
    }
  }

  Uint8List v1(PaperSize paperSize, CapabilityProfile profile) {
    try {
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
      
      // Validate user data
      if (bloc.user.valueWrapper.value == null) {
        throw Exception('Data user tidak valid');
      }
      
      // Print store name first
      String storeName = bloc.user.valueWrapper.value.namaToko.isEmpty
          ? bloc.user.valueWrapper.value.nama
          : bloc.user.valueWrapper.value.namaToko;
      
      if (storeName.isEmpty) {
        storeName = 'Toko';
      }
      
      bytes += ticket.text(
        storeName,
        styles: PosStyles(
          width: sizes[i + 1],
          height: sizes[i + 1],
          bold: true,
          align: PosAlign.center,
        ),
      );
      
      String storeAddress = bloc.user.valueWrapper.value.alamatToko.isEmpty
          ? bloc.user.valueWrapper.value.alamat
          : bloc.user.valueWrapper.value.alamatToko;
      
      if (storeAddress.isNotEmpty) {
        bytes += ticket.text(
          storeAddress,
          styles: PosStyles(
            align: PosAlign.center,
            width: sizes[i],
            height: sizes[i],
          ),
        );
      }
      
      // Print custom header text
      if (customHeaderText.isNotEmpty) {
        bytes += ticket.text(
          customHeaderText,
          styles: PosStyles(
            width: sizes[i],
            height: sizes[i],
            align: PosAlign.center,
          ),
          linesAfter: 1,
        );
      }
      
      // Validate transaction data
      if (trxData == null) {
        throw Exception('Data transaksi tidak valid');
      }
      
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
          'label': 'Tujuan',
          'value': trxData.tujuan ?? 'Tidak ada tujuan',
        },
      ]);
      
      if (trxData.print != null && trxData.print.isNotEmpty) {
        trxData.print.forEach((el) {
          if (!['token', 'jumlah', 'nominal', 'tagihan', 'admin']
              .contains(el['label'].toString().toLowerCase())) {
            bytes += printLine(ticket, [
              {
                'label': el['label'] ?? 'Label',
                'value': _formatValue(el['value'], label: el['label']),
              },
            ]);
          }
        });
      }
      
      if (showSN) {
        if (trxData.print == null || trxData.print.isEmpty) {
          bytes += printLine(ticket, [
            {
              'label': 'SN',
              'value': trxData.sn ?? 'Tidak ada SN',
            },
          ]);
        }
      } else {
        bytes += ticket.hr();
        if (trxData.print != null) {
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
      }
      bytes += ticket.hr();
      if (showDefaultTagihan) {
        bytes += printLine(ticket, [
          {
            'label': 'Tagihan',
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
      if (packageName == 'com.funmo.id') {
        bytes += printLine(ticket, [
          {
            'label': 'Biaya Cetak',
            'value': formatRupiah(cetak),
          },
        ]);
      }
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
        linesAfter: 1,
      );
      // Print custom footer text if available
      if (customFooterText.isNotEmpty) {
        // Clean the footer text to remove invalid characters
        String cleanFooterText = customFooterText
            .replaceAll('\n', ' ')  // Replace newlines with spaces
            .replaceAll(RegExp(r'[^\x20-\x7E]'), ''); // Remove non-printable characters
        
        if (cleanFooterText.isNotEmpty) {
          bytes += ticket.text(
            cleanFooterText,
            styles: PosStyles(
              align: PosAlign.center,
              width: sizes[i],
              height: sizes[i],
            ),
            linesAfter: 3,
          );
        }
      }

      return Uint8List.fromList(bytes);
    } catch (e) {
      print('Error in v1 function: $e');
      throw Exception('Error membuat data struk: $e');
    }
  }

  Future<void> v2() async {
    await _bluetooth.printNewLine();
    // Print store name first
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
    // Print custom header text
    await _bluetooth.printCustom(
      customHeaderText,
      0,
      0,
    );
    await _bluetooth.printNewLine();
    await _bluetooth.printCustom(
        formatDate(trxData.created_at, 'dd MMMM yyyy HH:mm:ss'), 0, 0);
    await _bluetooth.printCustom('TrxID: ${trxData.id.toUpperCase()}', 0, 0);
    await _bluetooth.printCustom('------------------', 0, 1);
    await _bluetooth.printCustom('Transaksi:', 0, 0);
    // await _bluetooth.printLeftRight('Nama Produk', trxData.produk['nama'], 0);
    await _bluetooth.printLeftRight('Tujuan', trxData.tujuan, 0);
    trxData.print.forEach((el) async {
      if (!['token', 'jumlah', 'nominal', 'tagihan', 'admin']
          .contains(el['label'].toString().toLowerCase())) {
        await _bluetooth.printLeftRight(el['label'], _formatValue(el['value'], label: el['label']), 0);
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
    if (showDefaultTagihan) {
      await _bluetooth.printLeftRight('Tagihan', formatRupiah(harga), 0);
    }
    if (showDefaultAdmin) {
      await _bluetooth.printLeftRight('Admin', formatRupiah(admin), 0);
    }
    if (packageName == 'com.funmo.id') {
      await _bluetooth.printLeftRight('Biaya Cetak', formatRupiah(cetak), 0);
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
    // Print custom footer text if available
    if (customFooterText.isNotEmpty) {
      await _bluetooth.printCustom(
        customFooterText,
        0,
        1,
      );
    }
    await _bluetooth.printNewLine();
    await _bluetooth.printNewLine();
    await _bluetooth.printNewLine();
  }

  Future<bool> checkBluetooth() async {
    PermissionStatus status = await Permission.locationWhenInUse.request();
    bool isOn = await _bluetooth.isOn;

    if (status == PermissionStatus.granted) {
      if (isOn) {
        return true;
      } else {
        showToast(context, 'Bluetooth belum aktif');
        return false;
      }
    } else {
      showToast(context, 'Aplikasi memerlukan izin bluetooth');
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
    try {
      bool status = await checkBluetooth();
      if (!status) return;

      BluetoothDevice device = await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => SelectPrinterPage()));
      if (device == null) return;

      if (await _bluetooth.isConnected) await _bluetooth.disconnect();
      
      // Test connection
      bool connected = await _bluetooth.connect(device);
      if (!connected) {
        showToast(context, 'Gagal terhubung ke printer');
        return;
      }
      
      final _profile = await CapabilityProfile.load();
      if (_profile == null) {
        showToast(context, 'Gagal memuat profile printer');
        return;
      }

      // Validate transaction data
      if (trxData == null) {
        showToast(context, 'Data transaksi tidak valid');
        return;
      }

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
    } catch (e) {
      print('Print Error: $e');
      if (e.toString().contains('Bluetooth')) {
        showToast(context, 'Error koneksi Bluetooth: ${e.toString()}');
      } else if (e.toString().contains('data')) {
        showToast(context, 'Error data transaksi: ${e.toString()}');
      } else if (e.toString().contains('profile')) {
        showToast(context, 'Error profile printer: ${e.toString()}');
      } else {
        showToast(context, 'Gagal mencetak struk: ${e.toString()}');
      }
    } finally {
      try {
        await _bluetooth.disconnect();
      } catch (e) {
        print('Error disconnecting: $e');
      }
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
          Expanded(
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
                            // Always show header regardless of isLogoPrinter
                            Stack(
                              children: [
                                // Show logo if available and isLogoPrinter is true
                                isLogoPrinter && configAppBloc.iconApp.valueWrapper
                                            .value['logoPrinter'] != null
                                    ? Container(
                                        child: CachedNetworkImage(
                                          imageUrl: configAppBloc
                                              .iconApp
                                              .valueWrapper
                                              .value['logoPrinter'],
                                          height: 30,
                                        ),
                                      )
                                    : SizedBox(),
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Column(
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
                                            SizedBox(height: 5),
                                            Text(
                                              customHeaderText,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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
                                  Text('ID Pelanggan',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                      )),
                                  Text(trxData.tujuan,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                      ))
                                ]),
                            SizedBox(height: 10),
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
                                            _formatValue(trxData.print[i]['value'], label: trxData.print[i]['label']),
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
                            showDefaultTagihan
                                ? Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                        Text('Tagihan',
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
                                        Text('Admin',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                            )),
                                        Text(formatRupiah(admin),
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                            ))
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
                         //   SizedBox(height: 10),
                            // Align(
                            //   alignment: Alignment.topCenter,
                            //   child: Text(
                            //     'Struk ini merupakan bukti pembayaran yang sah'
                            //         .toUpperCase(),
                            //     style: TextStyle(
                            //       fontSize: 12,
                            //       fontFamily: 'Poppins',
                            //     ),
                            //   ),
                            // ),
                         //   SizedBox(height: 10),
                            // Align(
                            //   alignment: Alignment.center,
                            //   child: Text(
                            //     footerStruk,
                            //     textAlign: TextAlign.center,
                            //     style: TextStyle(
                            //       fontSize: 12,
                            //       fontFamily: 'Poppins',
                            //     ),
                            //   ),
                            // ),
                            SizedBox(height: 15),
                            if (customFooterText.isNotEmpty)
                              Align(
                                alignment: Alignment.center,
                                child: Text(
                                  customFooterText,
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
            heroTag: "network_print",
            child: Icon(Icons.wifi),
            backgroundColor: packageName == 'com.lariz.mobile'
                ? Theme.of(context).secondaryHeaderColor
                : Theme.of(context).primaryColor,
            onPressed: () async {
              try {
                // Generate receipt data using the same method as Bluetooth printing
                final receiptData = await generateReceiptData();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => NetworkPrinterCompletePage(
                      trx: trxData,
                      isPostpaid: widget.isPostpaid,
                      customReceiptData: receiptData,
                    ),
                  ),
                );
              } catch (e) {
                showToast(context, 'Error generating receipt data: $e');
              }
            },
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "bluetooth_print",
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

abstract class PrintPreviewSbyController extends State<PrintPreviewSby>
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
  String labelHarga = "Tagihan";
  String customHeaderText = "";
  String customFooterText = "";

  TextEditingController txtHarga = TextEditingController();
  TextEditingController txtAdmin = TextEditingController();
  TextEditingController txtCetak = TextEditingController();

  void getData() async {
    http.Response response = await http.get(
        Uri.parse('$apiUrl/trx/${widget.trx.id}/print'),
        headers: {'Authorization': bloc.token.valueWrapper.value});

    if (response.statusCode == 200) {
      var responseData = json.decode(response.body)['data'];
      trxData = TrxModel.fromJson(responseData);
      
      // Extract custom header and footer text
      customHeaderText = responseData['header_text'] ?? "STRUK PEMBAYARAN PDAM SURYA SEMBADA KOTA SURABAYA";
      //customFooterText = responseData['footer_text'] ?? "";
      customFooterText = "PDAM SURABAYA MENYATAKAN STRUK INI SEBAGAI BUKTI PEMBAYARAN YANG SAH, MOHON DISIMPAN. INFO TAGIHAN DIAKSES DI www.pdam-sby.go.id CALL CENTER (031)-292-6666.";


      print("=== CUSTOM HEADER TEXT ===");
      print("Custom Header Text: $customHeaderText");
      print("=== CUSTOM FOOTER TEXT ===");
      print("Custom Footer Text: $customFooterText");
      
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

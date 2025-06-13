// @dart=2.9

import 'dart:convert';

import 'dart:async';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile/bloc/Api.dart';
import 'package:mobile/bloc/Bloc.dart';
import 'package:mobile/component/alert.dart';
import 'package:mobile/models/menu.dart';
import 'package:mobile/models/prepaid-denom.dart';
import 'package:mobile/modules.dart';
import 'package:mobile/screen/transaksi/inquiry_prepaid.dart';
import 'package:mobile/screen/transaksi/list_voucher_denom.dart';
import 'package:mobile/screen/transaksi/verifikasi_pin.dart';
import 'package:http/http.dart' as http;

class VoucherBulkPage extends StatefulWidget {
  final MenuModel menu;
  const VoucherBulkPage(this.menu, {Key key}) : super(key: key);

  @override
  State<VoucherBulkPage> createState() => _VoucherBulkPageState();
}

class _VoucherBulkPageState extends State<VoucherBulkPage> {
  bool _loading = false;
  TextEditingController _voucherCode = TextEditingController();
  TextEditingController _voucherStartCode = TextEditingController();
  TextEditingController _voucherEndCode = TextEditingController();
  TextEditingController _voucherQuantity = TextEditingController();
  List<Map<String, dynamic>> _masterVouchers = [];
  List<Map<String, dynamic>> _vouchers = [];
  PrepaidDenomModel _denom;
  int totalHarga = 0;
  bool _isPromo = false;
  int _filteredStatus = 0;
  String _voucherLabel = 'Semua Voucher :';

  @override
  void dispose() {
    _voucherCode.dispose();
    _voucherStartCode.dispose();
    _voucherEndCode.dispose();
    super.dispose();
  }

  void _calculateTotalHarga() {
    totalHarga = _denom.harga_jual * _vouchers.length;
    print("Total Harga: $totalHarga");
  }

  void _generateVoucher() {
    if (_loading) return;

    try {
      String startCodeText = _voucherStartCode.text.trim();
      String quantityText = _voucherQuantity.text.trim();

      if (startCodeText.isEmpty || quantityText.isEmpty) return;

      int startCode = int.parse(startCodeText);
      int quantity = int.parse(quantityText);

      _masterVouchers.clear();

      for (int i = startCode; i < startCode + quantity; i++) {
        _masterVouchers.add({
          'code': i.toString(),
          'selected': true,
          'status': 1,
        });
      }

      _vouchers = _masterVouchers;
      _calculateTotalHarga();

      setState(() {});
    } catch (err) {
      print(err);
    }
  }

  Future<void> _scanBarcode(String type) async {
    if (_loading) return;

    ScanResult result = await BarcodeScanner.scan();
    if (result.rawContent.isEmpty) return;
    setState(() {
      if (type == 'start') {
        _voucherStartCode.text = result.rawContent;
      } else if (type == 'end') {
        _voucherEndCode.text = result.rawContent;
      } else if (type == 'single') {
        _voucherCode.text = result.rawContent;
      }
    });
  }

  Future<void> _selectDenom() async {
    if (_loading) return;

    PrepaidDenomModel result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ListVoucherDenomPage(widget.menu),
      ),
    );

    if (result == null) return;

    setState(() {
      _denom = result;
      _isPromo = result.harga_promo != null &&
          result.harga_promo > 0 &&
          result.harga_jual > result.harga_promo;
    });
  }

  Future<void> _processVoucher() async {
    if (widget.menu.jenis == 5) {
      if (_denom == null) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              InquiryPrepaid(_denom.kode_produk, _voucherCode.text.trim()),
        ),
      );
      return;
    } else if (widget.menu.jenis == 6) {
      if (_denom == null || _vouchers.length == 0) return;

      bool isBalanceEnough = await _checkBalance();
      if (!isBalanceEnough) {
        return;
      }

      bool status = await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(
            'Setelah memasukkan kode PIN, sistem akan memotong saldo dan memproses transaksi anda tanpa melalui proses inquiry. Apakah anda yakin untuk melanjutkan transaksi ?',
            textAlign: TextAlign.justify,
          ),
          actions: [
            TextButton(
              child: Text(
                'LANJUT',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
            TextButton(
              child: Text(
                'BATAL',
                style: TextStyle(
                  color: Colors.red.shade600,
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
          ],
        ),
      );
      if (!status) return;

      try {
        if (_loading) return;

        setState(() {
          _loading = true;
        });

        String pin = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VerifikasiPin(),
          ),
        );
        if (pin == null) return;

        sendDeviceToken();

        for (int i = 0; i < _vouchers.length; i++) {
          Map<String, dynamic> voucher = _vouchers[i];

          if (!voucher['selected']) continue;
          if (voucher['status'] == 2) continue;
          await _purchaseVoucher(i, pin);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          Alert(
            'Transaksi sedang diproses, anda dapat memantau status transaksi pada halaman riwayat transaksi',
          ),
        );

        setState(() {
          _loading = false;
        });
      } catch (err) {
        print(err);
      } finally {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _purchaseVoucher(int index, String pin) async {
    try {
      var dataToSend = {
        'kode_produk': _denom.kode_produk,
        'tujuan': _vouchers[index]['code'],
        'counter': 1,
        'pin': pin,
      };

      http.Response response = await http
          .post(
            Uri.parse('$apiUrl/trx/prepaid/purchase'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': bloc.token.valueWrapper.value,
            },
            body: json.encode(dataToSend),
          )
          .timeout(Duration(minutes: 5)); // Menambahkan timeout di sini
      if (response.statusCode == 200) {
        _vouchers[index]['status'] = 2;
      } else {
        _vouchers[index]['status'] = 3;
      }
    } on TimeoutException catch (_) {
      // Menangani TimeoutException
      _vouchers[index]['status'] = 3;
      print('Request timed out');
    } catch (err) {
      _vouchers[index]['status'] = 3;
      print(err);
    } finally {
      setState(() {});
    }
  }

  Future<bool> _checkBalance() async {
    double totalAmount = _denom.harga_jual.toDouble() * _vouchers.length;

    if (bloc.user.valueWrapper.value.saldo < totalAmount) {
      showDialog(
          context: context,
          builder: (BuildContext ctx) {
            Future.delayed(Duration(seconds: 2), () {
              Navigator.of(ctx).pop(); // Menutup dialog/alert
            });
            return AlertDialog(
              title: Text('Error'),
              content: Text('Saldo tidak cukup.'),
            );
          });
      return false;
    } else {
      return true;
    }
  }

  void _updateFilter(int status) {
    if (_loading) {
      showToast(context,
          'Voucher sedang diproses, harap tunggu hingga voucher selesai diproses');
      return;
    }

    if (status == 0) {
      setState(() {
        _voucherLabel = 'Semua Voucher :';
        _vouchers = _masterVouchers;
      });
    } else if (status == 1) {
      setState(() {
        _voucherLabel = 'Voucher Belum Diproses :';
        _vouchers = _masterVouchers.where((el) => el['status'] == 1).toList();
      });
    } else if (status == 2) {
      setState(() {
        _voucherLabel = 'Voucher Berhasil :';
        _vouchers = _masterVouchers.where((el) => el['status'] == 2).toList();
      });
    } else if (status == 3) {
      setState(() {
        _voucherLabel = 'Voucher Gagal :';
        _vouchers = _masterVouchers.where((el) => el['status'] == 3).toList();
      });
    }
  }

  Widget _content() {
    if (widget.menu.jenis == 6) {
      // VOUCHER MASSAL
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kode Voucher Awal',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 5),
          TextFormField(
            controller: _voucherStartCode,
            enabled: !_loading,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(Icons.qr_code_2_rounded),
                color: Theme.of(context).primaryColor,
                onPressed: () => _scanBarcode('start'),
              ),
            ),
          ),
          SizedBox(height: 15),
          Text(
            'Jumlah Voucher',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 5),
          TextFormField(
            controller: _voucherQuantity,
            enabled: !_loading,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                ),
              ),
              // suffixIcon: IconButton(
              //   icon: Icon(Icons.qr_code_2_rounded),
              //   color: Theme.of(context).primaryColor,
              //   onPressed: () => _scanBarcode('end'),
              // ),
            ),
          ),
          SizedBox(height: 15),
          MaterialButton(
            minWidth: double.infinity,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            color: Theme.of(context).primaryColor,
            colorBrightness: Brightness.dark,
            elevation: 0,
            child: Text('Generate Voucher'),
            onPressed: _generateVoucher,
          ),
          Divider(),
          Container(
            width: double.infinity,
            height: 40,
            child: ListView(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                vertical: 5,
              ),
              children: [
                InkWell(
                  onTap: () => _updateFilter(0),
                  child: Container(
                    height: 15,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 10,
                    ),
                    child: Center(
                      child: Text(
                        'SEMUA STATUS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                InkWell(
                  onTap: () => _updateFilter(2),
                  child: Container(
                    height: 15,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      border: Border.all(
                        color: Colors.green.shade200,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 10,
                    ),
                    child: Center(
                      child: Text(
                        'BERHASIL',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                InkWell(
                  onTap: () => _updateFilter(3),
                  child: Container(
                    height: 15,
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      border: Border.all(
                        color: Colors.red.shade200,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 10,
                    ),
                    child: Center(
                      child: Text(
                        'GAGAL',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                InkWell(
                  onTap: () => _updateFilter(1),
                  child: Container(
                    height: 15,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      border: Border.all(
                        color: Colors.amber.shade200,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 10,
                    ),
                    child: Center(
                      child: Text(
                        'BELUM DIPROSES',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Text(
                _voucherLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Spacer(),
              Builder(
                builder: (_) {
                  int selectedVoucher = 0;
                  int totalVoucher = _vouchers.length;

                  _vouchers.forEach((voucher) {
                    if (voucher['selected']) selectedVoucher++;
                  });

                  return Text(
                    '$selectedVoucher / $totalVoucher',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 10),
          Expanded(
            child: _vouchers.length == 0
                ? Container(
                    child: Center(
                      child: Text(
                        'Tidak Ada Voucher'.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _vouchers.length,
                    itemBuilder: (_, i) {
                      Map<String, dynamic> voucher = _vouchers[i];
                      Color bgColor = Colors.transparent;

                      if (voucher['selected']) {
                        switch (voucher['status']) {
                          case 1:
                            bgColor = Colors.amber.shade100;
                            break;
                          case 2:
                            bgColor = Colors.green.shade100;
                            break;
                          case 3:
                            bgColor = Colors.red.shade100;
                            break;
                          default:
                            bgColor = Colors.transparent;
                        }
                      }

                      return Container(
                        padding: EdgeInsets.symmetric(vertical: 3),
                        decoration: BoxDecoration(
                          color: bgColor,
                          border: Border.symmetric(
                            horizontal: BorderSide(
                              color: Colors.grey.shade300,
                              width: .5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              fillColor: MaterialStateProperty.all(
                                Theme.of(context).primaryColor,
                              ),
                              value: voucher['selected'],
                              onChanged: (value) {
                                if (_loading) return;

                                setState(() {
                                  voucher['selected'] = value;
                                });
                              },
                            ),
                            Text(voucher['code']),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    } else {
      // VOUCHER MANUAL
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kode Voucher',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 5),
          TextFormField(
            controller: _voucherCode,
            enabled: !_loading,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(Icons.qr_code_2_rounded),
                color: Theme.of(context).primaryColor,
                onPressed: () => _scanBarcode('single'),
              ),
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voucher'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: _selectDenom,
                    child: _denom == null
                        ? Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12.5),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              border: Border.all(
                                color: Colors.grey,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Klik Untuk Pilih Produk'.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(.15),
                                  offset: Offset(3, 3),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            width: double.infinity,
                            child: ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey.shade200,
                                child: CachedNetworkImage(
                                  imageUrl: widget.menu.icon,
                                  errorWidget: (_, __, ___) => SizedBox(),
                                ),
                              ),
                              title: Text(
                                _denom.nama,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(_denom.description),
                              trailing: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    formatRupiah(_isPromo
                                        ? _denom.harga_promo
                                        : _denom.harga_jual),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade600,
                                    ),
                                  ),
                                  _isPromo
                                      ? Text(
                                          formatRupiah(_denom.harga_jual),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.red.shade600,
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        )
                                      : SizedBox(),
                                ],
                              ),
                            ),
                          ),
                  ),
                  SizedBox(height: 15),
                  Expanded(
                    child: _content(),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(15),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              color: Colors.grey.withOpacity(.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total',
                            style: TextStyle(color: Colors.grey, fontSize: 11)),
                        SizedBox(height: 3),
                        Text(
                          formatRupiah(totalHarga),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: MaterialButton(
                      minWidth: double.infinity,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      color: Theme.of(context).primaryColor,
                      disabledColor: Colors.grey.shade200,
                      colorBrightness: Brightness.dark,
                      elevation: 0,
                      shape: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey)),
                      child: _loading
                          ? SpinKitThreeBounce(color: Colors.white, size: 20)
                          : Text(widget.menu.jenis == 5
                              ? 'Lanjutkan'
                              : 'Proses Voucher'),
                      onPressed: _denom == null ? null : _processVoucher,
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

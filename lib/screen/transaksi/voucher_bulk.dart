// @dart=2.9

import 'dart:convert';

import 'dart:async';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mobile/bloc/Api.dart';
import 'package:mobile/bloc/Bloc.dart';
import 'package:mobile/component/alert.dart';
import 'package:mobile/config.dart';
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
  List<Map<String, dynamic>> _masterVouchers = [];
  List<Map<String, dynamic>> _vouchers = [];
  PrepaidDenomModel _denom;
  int totalHarga = 0;
  bool _isPromo = false;
  int _filteredStatus = 0;
  String _voucherLabel = 'Semua Voucher :';

  @override
  void dispose() {
    print('=== DEBUG: Disposing VoucherBulkPage ===');
    print('DEBUG: Disposing text controllers');
    _voucherCode.dispose();
    _voucherStartCode.dispose();
    _voucherEndCode.dispose();
    super.dispose();
    print('DEBUG: VoucherBulkPage disposed');
  }

  void _calculateTotalHarga() {
    print('=== DEBUG: Starting _calculateTotalHarga ===');
    print('DEBUG: Denom harga_jual: ${_denom?.harga_jual ?? "null"}');
    print('DEBUG: Vouchers length: ${_vouchers.length}');
    
    totalHarga = _denom.harga_jual * _vouchers.length;
    print("DEBUG: Total Harga calculated: $totalHarga");
  }

  void _generateVoucher() {
    print('=== DEBUG: Starting _generateVoucher ===');
    print('DEBUG: Loading state: $_loading');
    
    if (_loading) {
      print('DEBUG: Currently loading, returning');
      return;
    }

    try {
      String startCodeText = _voucherStartCode.text.trim();
      String endCodeText = _voucherEndCode.text.trim();
      
      print('DEBUG: Start code text: "$startCodeText"');
      print('DEBUG: End code text: "$endCodeText"');

      if (startCodeText.isEmpty || endCodeText.isEmpty) {
        print('DEBUG: Start or end code is empty, returning');
        return;
      }

      int startCode = int.parse(startCodeText);
      int endCode = int.parse(endCodeText);
      
      print('DEBUG: Start code: $startCode');
      print('DEBUG: End code: $endCode');

      if (startCode == endCode) {
        print('DEBUG: Start and end codes are the same, returning');
        return;
      }
      
      print('DEBUG: Clearing master vouchers');
      _masterVouchers.clear();

      int codeLength = startCodeText.length;
      print('DEBUG: Code length: $codeLength');

      if (startCode <= endCode) {
        print('DEBUG: Generating vouchers in ascending order');
        for (int i = startCode; i <= endCode; i++) {
          String code = i.toString().padLeft(codeLength, '0');
          _masterVouchers.add({
            'code': code,
            'selected': true,
            'status': 1,
          });
        }
      } else {
        print('DEBUG: Generating vouchers in descending order');
        for (int i = startCode; i >= endCode; i--) {
          String code = i.toString().padLeft(codeLength, '0');
          _masterVouchers.add({
            'code': code,
            'selected': true,
            'status': 1,
          });
        }
      }

      print('DEBUG: Total vouchers generated: ${_masterVouchers.length}');
      _vouchers = _masterVouchers;
      _calculateTotalHarga();

      print('DEBUG: Setting state');
      setState(() {});
    } catch (err) {
      print('DEBUG: Error in _generateVoucher: $err');
      print('DEBUG: Error type: ${err.runtimeType}');
    }
  }

  Future<void> _scanBarcode(String type) async {
    print('=== DEBUG: Starting _scanBarcode ===');
    print('DEBUG: Scan type: $type');
    print('DEBUG: Loading state: $_loading');
    
    if (_loading) {
      print('DEBUG: Currently loading, returning');
      return;
    }

    print('DEBUG: Starting barcode scanner...');
    ScanResult result = await BarcodeScanner.scan();
    print('DEBUG: Scan result received');
    print('DEBUG: Raw content: "${result.rawContent}"');
    print('DEBUG: Raw content length: ${result.rawContent.length}');
    
    if (result.rawContent.isEmpty) {
      print('DEBUG: Raw content is empty, returning');
      return;
    }
    
    print('DEBUG: Setting scanned content to text field');
    setState(() {
      if (type == 'start') {
        _voucherStartCode.text = result.rawContent;
        print('DEBUG: Set start code to: ${result.rawContent}');
      } else if (type == 'end') {
        _voucherEndCode.text = result.rawContent;
        print('DEBUG: Set end code to: ${result.rawContent}');
      } else if (type == 'single') {
        _voucherCode.text = result.rawContent;
        print('DEBUG: Set single code to: ${result.rawContent}');
      }
    });
  }

  Future<void> _selectDenom() async {
    print('=== DEBUG: Starting _selectDenom ===');
    print('DEBUG: Loading state: $_loading');
    
    if (_loading) {
      print('DEBUG: Currently loading, returning');
      return;
    }

    print('DEBUG: Navigating to ListVoucherDenomPage');
    PrepaidDenomModel result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ListVoucherDenomPage(widget.menu),
      ),
    );

    print('DEBUG: Result from denom selection: ${result != null ? "Selected" : "Cancelled"}');
    if (result == null) {
      print('DEBUG: No denom selected, returning');
      return;
    }

    print('DEBUG: Setting denom data');
    print('DEBUG: Denom kode_produk: ${result.kode_produk}');
    print('DEBUG: Denom nama: ${result.nama}');
    print('DEBUG: Denom harga_jual: ${result.harga_jual}');
    print('DEBUG: Denom harga_promo: ${result.harga_promo}');
    
    setState(() {
      _denom = result;
      _isPromo = result.harga_promo != null &&
          result.harga_promo > 0 &&
          result.harga_jual > result.harga_promo;
    });
    
    print('DEBUG: Is promo: $_isPromo');
  }

  Future<void> _processVoucher() async {
    print('=== DEBUG: Starting _processVoucher ===');
    print('DEBUG: Menu jenis: ${widget.menu.jenis}');
    print('DEBUG: Denom is null: ${_denom == null}');
    print('DEBUG: Vouchers length: ${_vouchers.length}');
    
    if (widget.menu.jenis == 5) {
      print('DEBUG: Processing single voucher (jenis 5)');
      if (_denom == null) {
        print('DEBUG: Denom is null, returning');
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              InquiryPrepaid(_denom.kode_produk, _voucherCode.text.trim()),
        ),
      );
      return;
    } else if (widget.menu.jenis == 6) {
      print('DEBUG: Processing bulk voucher (jenis 6)');
      if (_denom == null || _vouchers.length == 0) {
        print('DEBUG: Denom is null or vouchers empty, returning');
        return;
      }

      print('DEBUG: Checking balance...');
      bool isBalanceEnough = await _checkBalance();
      print('DEBUG: Balance check result: $isBalanceEnough');
      if (!isBalanceEnough) {
        print('DEBUG: Insufficient balance, returning');
        return;
      }

      print('DEBUG: Showing confirmation dialog...');
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
      print('DEBUG: Dialog result: $status');
      if (!status) return;

      try {
        if (_loading) {
          print('DEBUG: Already loading, returning');
          return;
        }

        print('DEBUG: Setting loading to true');
        setState(() {
          _loading = true;
        });

        print('DEBUG: Navigating to PIN verification...');
        String pin = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VerifikasiPin(),
          ),
        );
        print('DEBUG: PIN verification result: ${pin != null ? "PIN received" : "PIN cancelled"}');
        if (pin == null) return;

        print('DEBUG: Sending device token...');
        sendDeviceToken();

        print('DEBUG: Starting voucher processing loop...');
        print('DEBUG: Total vouchers to process: ${_vouchers.length}');
        
        for (int i = 0; i < _vouchers.length; i++) {
          Map<String, dynamic> voucher = _vouchers[i];
          print('DEBUG: Processing voucher $i: ${voucher['code']}');
          print('DEBUG: Voucher selected: ${voucher['selected']}');
          print('DEBUG: Voucher status: ${voucher['status']}');

          if (!voucher['selected']) {
            print('DEBUG: Voucher not selected, skipping');
            continue;
          }
          if (voucher['status'] == 2) {
            print('DEBUG: Voucher already processed, skipping');
            continue;
          }
          
          print('DEBUG: Calling _purchaseVoucher for index $i');
          await _purchaseVoucher(i, pin);
        }

        print('DEBUG: All vouchers processed, showing success message');
        ScaffoldMessenger.of(context).showSnackBar(
          Alert(
            'Transaksi sedang diproses, anda dapat memantau status transaksi pada halaman riwayat transaksi',
          ),
        );

        setState(() {
          _loading = false;
        });
      } catch (err) {
        print('DEBUG: Error in _processVoucher: $err');
        print('DEBUG: Error type: ${err.runtimeType}');
      } finally {
        print('DEBUG: Setting loading to false in finally block');
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _purchaseVoucher(int index, String pin) async {
    print('=== DEBUG: Starting voucher purchase for index $index ===');
          print('DEBUG: API URL: $apiUrl/trx/prepaid/purchase');
    print('DEBUG: Token available: ${bloc.token.valueWrapper.value != null}');
    print('DEBUG: Token length: ${bloc.token.valueWrapper.value?.length ?? 0}');
    print('DEBUG: Denom kode_produk: ${_denom.kode_produk}');
    print('DEBUG: Voucher code: ${_vouchers[index]['code']}');
    
    try {
      var dataToSend = {
        'kode_produk': _denom.kode_produk,
        'tujuan': _vouchers[index]['code'],
        'counter': 1,
        'pin': pin,
      };
      
      print('DEBUG: Request data: ${json.encode(dataToSend)}');
      print('DEBUG: Headers: ${{
        'Content-Type': 'application/json',
        'Authorization': bloc.token.valueWrapper.value,
      }}');

      print('DEBUG: Making HTTP request...');
      http.Response response = await http
          .post(
            Uri.parse('$apiUrl/trx/prepaid/purchase'),
            headers: {  
              'Content-Type': 'application/json',
              'Authorization': bloc.token.valueWrapper.value,
            },
            body: json.encode(dataToSend),
          )
          .timeout(Duration(minutes: 5));
      
      print('DEBUG: Response received');
      print('DEBUG: Status code: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        _vouchers[index]['status'] = 2;
        _vouchers[index]['trx_id'] = responseData['data']['trx_id'];
        _vouchers[index]['harga'] = responseData['data']['harga'];
        print('DEBUG: Voucher purchase successful - TRX ID: ${responseData['data']['trx_id']}');
      } else {
        _vouchers[index]['status'] = 3;
        print('DEBUG: Voucher purchase failed with status: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      _vouchers[index]['status'] = 3;
      print('DEBUG: TimeoutException caught: $e');
      print('DEBUG: Request timed out after 5 minutes');
    } catch (err) {
      _vouchers[index]['status'] = 3;
      print('DEBUG: Unexpected error caught: $err');
      print('DEBUG: Error type: ${err.runtimeType}');
      print('DEBUG: Error toString: ${err.toString()}');
      
      // Check if it's an SSL/Handshake error
      if (err.toString().contains('HandshakeException') || 
          err.toString().contains('handshake') ||
          err.toString().contains('SSL')) {
        print('DEBUG: This appears to be an SSL/Handshake error');
        print('DEBUG: Full error details: $err');
      }
      
      // Check if it's a network connectivity issue
      if (err.toString().contains('SocketException') ||
          err.toString().contains('Connection') ||
          err.toString().contains('Network')) {
        print('DEBUG: This appears to be a network connectivity issue');
        print('DEBUG: Full error details: $err');
      }
    } finally {
      print('DEBUG: Setting state and completing voucher purchase for index $index');
      setState(() {});
    }
  }

  Future<bool> _checkBalance() async {
    print('=== DEBUG: Starting _checkBalance ===');
    print('DEBUG: Denom harga_jual: ${_denom.harga_jual}');
    print('DEBUG: Vouchers length: ${_vouchers.length}');
    
    double totalAmount = _denom.harga_jual.toDouble() * _vouchers.length;
    print('DEBUG: Total amount needed: $totalAmount');
    print('DEBUG: User saldo: ${bloc.user.valueWrapper.value.saldo}');
    print('DEBUG: Is balance sufficient: ${bloc.user.valueWrapper.value.saldo >= totalAmount}');

    if (bloc.user.valueWrapper.value.saldo < totalAmount) {
      print('DEBUG: Insufficient balance, showing dialog');
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
      print('DEBUG: Balance is sufficient');
      return true;
    }
  }

  void _updateFilter(int status) {
    print('=== DEBUG: Starting _updateFilter ===');
    print('DEBUG: Filter status: $status');
    print('DEBUG: Loading state: $_loading');
    
    if (_loading) {
      print('DEBUG: Currently loading, showing toast and returning');
      showToast(context,
          'Voucher sedang diproses, harap tunggu hingga voucher selesai diproses');
      return;
    }

    print('DEBUG: Master vouchers count: ${_masterVouchers.length}');
    
    if (status == 0) {
      print('DEBUG: Showing all vouchers');
      setState(() {
        _voucherLabel = 'Semua Voucher :';
        _vouchers = _masterVouchers;
      });
    } else if (status == 1) {
      print('DEBUG: Showing unprocessed vouchers');
      var filtered = _masterVouchers.where((el) => el['status'] == 1).toList();
      print('DEBUG: Unprocessed vouchers count: ${filtered.length}');
      setState(() {
        _voucherLabel = 'Voucher Belum Diproses :';
        _vouchers = filtered;
      });
    } else if (status == 2) {
      print('DEBUG: Showing successful vouchers');
      var filtered = _masterVouchers.where((el) => el['status'] == 2).toList();
      print('DEBUG: Successful vouchers count: ${filtered.length}');
      setState(() {
        _voucherLabel = 'Voucher Berhasil :';
        _vouchers = filtered;
      });
    } else if (status == 3) {
      print('DEBUG: Showing failed vouchers');
      var filtered = _masterVouchers.where((el) => el['status'] == 3).toList();
      print('DEBUG: Failed vouchers count: ${filtered.length}');
      setState(() {
        _voucherLabel = 'Voucher Gagal :';
        _vouchers = filtered;
      });
    }
    
    print('DEBUG: Filtered vouchers count: ${_vouchers.length}');
  }

  Widget _content() {
    print('=== DEBUG: Building _content ===');
    print('DEBUG: Menu jenis: ${widget.menu.jenis}');
    
    if (widget.menu.jenis == 6) {
      print('DEBUG: Building bulk voucher content');
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
          packageName == 'com.eralink.mobileapk'
              ? TextFormField(
                  controller: _voucherStartCode,
                  enabled: !_loading,
                  keyboardType: TextInputType.number,
                  cursorColor: Theme.of(context).primaryColor,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: packageName == 'com.lariz.mobile'
                            ? Theme.of(context).secondaryHeaderColor
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.qr_code_2_rounded),
                      color: packageName == 'com.lariz.mobile'
                          ? Theme.of(context).secondaryHeaderColor
                          : Theme.of(context).primaryColor,
                      onPressed: () => _scanBarcode('start'),
                    ),
                  ),
                )
              : TextFormField(
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
                        color: packageName == 'com.lariz.mobile'
                            ? Theme.of(context).secondaryHeaderColor
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.qr_code_2_rounded),
                      color: packageName == 'com.lariz.mobile'
                          ? Theme.of(context).secondaryHeaderColor
                          : Theme.of(context).primaryColor,
                      onPressed: () => _scanBarcode('start'),
                    ),
                  ),
                ),
          SizedBox(height: 15),
          Text(
            'Kode Voucher Akhir',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 5),
          packageName == 'com.eralink.mobileapk'
              ? TextFormField(
                  controller: _voucherEndCode,
                  enabled: !_loading,
                  keyboardType: TextInputType.number,
                  cursorColor: Theme.of(context).primaryColor,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: packageName == 'com.lariz.mobile'
                            ? Theme.of(context).secondaryHeaderColor
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.qr_code_2_rounded),
                      color: packageName == 'com.lariz.mobile'
                          ? Theme.of(context).secondaryHeaderColor
                          : Theme.of(context).primaryColor,
                      onPressed: () => _scanBarcode('end'),
                    ),
                  ),
                )
              : TextFormField(
                  controller: _voucherEndCode,
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
                        color: packageName == 'com.lariz.mobile'
                            ? Theme.of(context).secondaryHeaderColor
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.qr_code_2_rounded),
                      color: packageName == 'com.lariz.mobile'
                          ? Theme.of(context).secondaryHeaderColor
                          : Theme.of(context).primaryColor,
                      onPressed: () => _scanBarcode('end'),
                    ),
                  ),
                ),
          SizedBox(height: 15),
          MaterialButton(
            minWidth: double.infinity,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            color: packageName == 'com.lariz.mobile'
                ? Theme.of(context).secondaryHeaderColor
                : Theme.of(context).primaryColor,
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
                                packageName == 'com.lariz.mobile'
                                    ? Theme.of(context).secondaryHeaderColor
                                    : Theme.of(context).primaryColor,
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
          packageName == 'com.eralink.mobileapk'
              ? TextFormField(
                  controller: _voucherCode,
                  enabled: !_loading,
                  keyboardType: TextInputType.number,
                  cursorColor: Theme.of(context).primaryColor,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: packageName == 'com.lariz.mobile'
                            ? Theme.of(context).secondaryHeaderColor
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.qr_code_2_rounded),
                      color: packageName == 'com.lariz.mobile'
                          ? Theme.of(context).secondaryHeaderColor
                          : Theme.of(context).primaryColor,
                      onPressed: () => _scanBarcode('single'),
                    ),
                  ),
                )
              : TextFormField(
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
                        color: packageName == 'com.lariz.mobile'
                            ? Theme.of(context).secondaryHeaderColor
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.qr_code_2_rounded),
                      color: packageName == 'com.lariz.mobile'
                          ? Theme.of(context).secondaryHeaderColor
                          : Theme.of(context).primaryColor,
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
    print('=== DEBUG: Building VoucherBulkPage ===');
    print('DEBUG: Loading state: $_loading');
    print('DEBUG: Denom is null: ${_denom == null}');
    print('DEBUG: Vouchers count: ${_vouchers.length}');
    print('DEBUG: Total harga: $totalHarga');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Voucher'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: packageName == 'com.lariz.mobile'
            ? Theme.of(context).secondaryHeaderColor
            : Theme.of(context).primaryColor,
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
          // Padding(
          //   padding: EdgeInsets.all(15),
          //   child: MaterialButton(
          //     minWidth: double.infinity,
          //     materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          //     color: Theme.of(context).primaryColor,
          //     disabledColor: Colors.grey.shade200,
          //     colorBrightness: Brightness.dark,
          //     elevation: 0,
          //     shape: OutlineInputBorder(
          //         borderRadius: BorderRadius.circular(10),
          //         borderSide: BorderSide(color: Colors.grey)),
          //     child: _loading
          //         ? SpinKitThreeBounce(
          //             color: Colors.white,
          //             size: 20,
          //           )
          //         : Text(
          //             widget.menu.jenis == 5 ? 'Lanjutkan' : 'Proses Voucher'),
          //     onPressed: _denom == null ? null : _processVoucher,
          //   ),
          // ),
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
                            color: packageName == 'com.lariz.mobile'
                                ? Theme.of(context).secondaryHeaderColor
                                : Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: MaterialButton(
                      minWidth: double.infinity,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      color: packageName == 'com.lariz.mobile'
                          ? Theme.of(context).secondaryHeaderColor
                          : Theme.of(context).primaryColor,
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
            // child: MaterialButton(
            //   minWidth: double.infinity,
            //   materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            //   color: Theme.of(context).primaryColor,
            //   disabledColor: Colors.grey.shade200,
            //   colorBrightness: Brightness.dark,
            //   elevation: 0,
            //   shape: OutlineInputBorder(
            //       borderRadius: BorderRadius.circular(10),
            //       borderSide: BorderSide(color: Colors.grey)),
            //   child: _loading
            //       ? SpinKitThreeBounce(
            //           color: Colors.white,
            //           size: 20,
            //         )
            //       : Text(
            //           widget.menu.jenis == 5 ? 'Lanjutkan' : 'Proses Voucher'),
            //   onPressed: _denom == null ? null : _processVoucher,
            // ),
          ),
        ],
      ),
    );
  }
}

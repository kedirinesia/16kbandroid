import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:mobile/bloc/Bloc.dart' show bloc;
import 'package:mobile/config.dart';
import 'package:mobile/models/trx.dart';
import 'package:mobile/screen/custom_alert_dialog.dart';

class CupsPrinter {
  final String ipAddress;
  final int port;
  final String printerName;
  final String? username;
  final String? password;

  CupsPrinter({
    required this.ipAddress,
    this.port = 631, // Default CUPS port
    required this.printerName,
    this.username,
    this.password,
  });

  // Test connection to CUPS printer
  Future<bool> testConnection() async {
    try {
      final url = 'http://$ipAddress:$port/printers/$printerName';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (username != null && password != null)
            'Authorization': 'Basic ${base64Encode(utf8.encode('$username:$password'))}',
        },
      );
      
      print('CUPS Connection Test: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('CUPS Connection Error: $e');
      return false;
    }
  }

  // Print using CUPS IPP protocol
  Future<bool> printViaIPP(Uint8List data) async {
    try {
      final url = 'http://$ipAddress:$port/printers/$printerName';
      
      // Create IPP request
      final ippRequest = _createIPPRequest(data);
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/ipp',
          if (username != null && password != null)
            'Authorization': 'Basic ${base64Encode(utf8.encode('$username:$password'))}',
        },
        body: ippRequest,
      );

      print('IPP Print Response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('IPP Print Error: $e');
      return false;
    }
  }

  // Print using raw TCP connection (alternative method)
  Future<bool> printViaRawTCP(Uint8List data) async {
    try {
      final socket = await Socket.connect(ipAddress, port);
      
      // Send raw print data
      socket.add(data);
      await socket.flush();
      await socket.close();
      
      print('Raw TCP Print: Success');
      return true;
    } catch (e) {
      print('Raw TCP Print Error: $e');
      return false;
    }
  }

  // Create IPP request
  Uint8List _createIPPRequest(Uint8List printData) {
    // Simple IPP request structure
    final buffer = ByteData(8 + printData.length);
    
    // IPP version
    buffer.setUint8(0, 2); // Major version
    buffer.setUint8(1, 0); // Minor version
    
    // Operation ID (Print-Job = 2)
    buffer.setUint16(2, 2, Endian.big);
    
    // Request ID
    buffer.setUint32(4, 1, Endian.big);
    
    // Add print data
    final result = Uint8List.fromList([
      ...buffer.buffer.asUint8List(0, 8),
      ...printData,
    ]);
    
    return result;
  }
}

class CupsPrinterPage extends StatefulWidget {
  final TrxModel trx;
  final bool isPostpaid;

  CupsPrinterPage({Key? key, required this.trx, this.isPostpaid = false}) : super(key: key);

  @override
  _CupsPrinterPageState createState() => _CupsPrinterPageState();
}

class _CupsPrinterPageState extends State<CupsPrinterPage> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _printerNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String _status = 'Ready';
  CupsPrinter? _printer;

  @override
  void initState() {
    super.initState();
    _portController.text = '631'; // Default CUPS port
    _loadSavedSettings();
  }

  void _loadSavedSettings() {
    // Load saved printer settings from SharedPreferences
    // This is a placeholder - implement based on your storage method
    _ipController.text = '192.168.1.100'; // Default IP
    _printerNameController.text = 'Thermal_Printer'; // Default printer name
  }

  Future<void> _testConnection() async {
    if (_ipController.text.isEmpty || _printerNameController.text.isEmpty) {
      _showError('IP Address dan Printer Name harus diisi');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Testing connection...';
    });

    try {
      _printer = CupsPrinter(
        ipAddress: _ipController.text,
        port: int.tryParse(_portController.text) ?? 631,
        printerName: _printerNameController.text,
        username: _usernameController.text.isNotEmpty ? _usernameController.text : null,
        password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
      );

      bool isConnected = await _printer!.testConnection();
      
      setState(() {
        _isLoading = false;
        _status = isConnected ? 'Connection successful!' : 'Connection failed';
      });

      if (isConnected) {
        _showSuccess('Printer berhasil terhubung!');
      } else {
        _showError('Gagal terhubung ke printer. Periksa IP address dan nama printer.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Error: $e';
      });
      _showError('Error: $e');
    }
  }

  Future<void> _printReceipt() async {
    if (_printer == null) {
      _showError('Test koneksi terlebih dahulu');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Printing receipt...';
    });

    try {
      // Validate data first
      if (widget.trx == null) {
        _showError('Data transaksi tidak tersedia');
        return;
      }
      
      if (bloc.user.valueWrapper?.value == null) {
        _showError('Data user tidak tersedia');
        return;
      }
      
      debugPrint('✅ Generating print data for transaction: ${widget.trx.id}');
      
      // Generate print data using ESC/POS
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      
      List<int> bytes = [];
      
      String storeName = bloc.user.valueWrapper?.value?.namaToko?.isEmpty == true
          ? bloc.user.valueWrapper?.value?.nama ?? ''
          : bloc.user.valueWrapper?.value?.namaToko ?? '';
          
      if (storeName.isEmpty) {
        storeName = 'Toko';
      }
      
      bytes += generator.text(
        storeName,
        styles: PosStyles(
          bold: true,
          align: PosAlign.center,
        ),
      );
      bytes += generator.text(
        bloc.user.valueWrapper?.value?.alamatToko?.isEmpty == true
            ? bloc.user.valueWrapper?.value?.alamat ?? ''
            : bloc.user.valueWrapper?.value?.alamatToko ?? '',
        styles: PosStyles(align: PosAlign.center),
        linesAfter: 1,
      );
      bytes += generator.text('TrxID: ${widget.trx.id.toUpperCase()}');
      bytes += generator.hr();
      bytes += generator.text('Transaksi:');
      bytes += generator.text('Nama Produk: ${widget.trx.produk['nama']}');
      bytes += generator.text('Tujuan: ${widget.trx.tujuan}');
      bytes += generator.hr();
      bytes += generator.text('Total: ${widget.trx.harga_jual}');
      bytes += generator.hr();
      bytes += generator.text('STRUK INI MERUPAKAN BUKTI PEMBAYARAN YANG SAH');
      bytes += generator.feed(3);

      final printData = Uint8List.fromList(bytes);
      
      // Try IPP first, then fallback to raw TCP
      bool success = await _printer!.printViaIPP(printData);
      
      if (!success) {
        success = await _printer!.printViaRawTCP(printData);
      }

      setState(() {
        _isLoading = false;
        _status = success ? 'Print successful!' : 'Print failed';
      });

      if (success) {
        _showSuccess('Struk berhasil dicetak!');
      } else {
        _showError('Gagal mencetak struk');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Error: $e';
      });
      _showError('Error: $e');
    }
  }

  void _showSuccess(String message) {
    showCustomDialog(
      context: context,
      type: DialogType.success,
      title: 'Berhasil',
      content: message,
    );
  }

  void _showError(String message) {
    showCustomDialog(
      context: context,
      type: DialogType.error,
      title: 'Error',
      content: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CUPS Printer Setup'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Printer Settings',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _ipController,
                      decoration: InputDecoration(
                        labelText: 'IP Address',
                        hintText: '192.168.1.100',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _portController,
                      decoration: InputDecoration(
                        labelText: 'Port',
                        hintText: '631',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _printerNameController,
                      decoration: InputDecoration(
                        labelText: 'Printer Name',
                        hintText: 'Thermal_Printer',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(_status),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _testConnection,
                            child: _isLoading 
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text('Test Connection'),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading || _printer == null ? null : _printReceipt,
                            child: Text('Print Receipt'),
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
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _printerNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
} 
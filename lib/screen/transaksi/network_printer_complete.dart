import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:mobile/bloc/Bloc.dart' show bloc;
import 'package:mobile/models/trx.dart';
import 'package:mobile/screen/custom_alert_dialog.dart';
import 'package:mobile/modules.dart';
import 'package:http/http.dart' as http;

class NetworkPrinterComplete {
  final String ipAddress;
  final int port;
  final String? printerName;

  NetworkPrinterComplete({
    required this.ipAddress,
    this.port = 9100,
    this.printerName,
  });

  Future<bool> testConnection() async {
    try {
      if (port == 631) {
        // Test CUPS connection
        final cupsConnected = await _testCUPSConnection();
        
        // Also test direct printer connection
        debugPrint('Testing direct printer connection to port 9100');
        try {
          final socket = await Socket.connect(ipAddress, 9100, timeout: Duration(seconds: 3));
          await socket.close();
          debugPrint('Direct printer connection: Success');
          return cupsConnected;
        } catch (e) {
          debugPrint('Direct printer connection failed: $e');
          return cupsConnected;
        }
      } else {
        // Test raw TCP connection
        final socket = await Socket.connect(ipAddress, port, timeout: Duration(seconds: 5));
        await socket.close();
        return true;
      }
    } catch (e) {
      debugPrint('Connection test error: $e');
      return false;
    }
  }

  Future<bool> _testCUPSConnection() async {
    try {
      // Test 1: General CUPS connection
      final url = 'http://$ipAddress:$port/printers/';
      debugPrint('Testing CUPS connection to: $url');
      
      final response = await http.get(Uri.parse(url));
      debugPrint('CUPS test response: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        return false;
      }
      
      // Test 2: Check specific printer
      final printerName = this.printerName ?? 'default';
      final printerUrl = 'http://$ipAddress:$port/printers/$printerName';
      debugPrint('Testing printer: $printerUrl');
      
      final printerResponse = await http.get(Uri.parse(printerUrl));
      debugPrint('Printer test response: ${printerResponse.statusCode}');
      
      return printerResponse.statusCode == 200;
    } catch (e) {
      debugPrint('CUPS test error: $e');
      return false;
    }
  }

  Future<bool> print(Uint8List data) async {
    try {
      // Try CUPS IPP first (port 631)
      if (port == 631) {
        return await _printViaCUPS(data);
      } else {
        // Try raw TCP (port 9100)
        return await _printViaRawTCP(data);
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> _printViaCUPS(Uint8List data) async {
    try {
      final printerName = this.printerName ?? 'default';
      
      // Method 1: Try direct socket to CUPS server port 9100 (most reliable)
      debugPrint('CUPS: Trying direct socket to CUPS server port 9100');
      try {
        // Connect to CUPS server and forward to localhost:9100
        final socket = await Socket.connect(ipAddress, 9100, timeout: Duration(seconds: 5));
        socket.add(data);
        await socket.flush();
        await socket.close();
        debugPrint('Direct socket to CUPS server: Success');
        return true;
      } catch (e) {
        debugPrint('Direct socket to CUPS server failed: $e');
      }

      // Method 2: Try raw data submission as fallback
      debugPrint('CUPS: Trying raw data submission to http://$ipAddress:$port/printers/$printerName');
      try { 
        final url = 'http://$ipAddress:$port/printers/$printerName';
        
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/octet-stream',
            'Content-Length': '${data.length}',
          },
          body: data,
        );

        debugPrint('CUPS Raw Data Response: ${response.statusCode}');
        debugPrint('CUPS Response Body: ${response.body}');
        
        if (response.statusCode == 200) {
          debugPrint('CUPS: Raw data submission successful');
          return true;
        }
      } catch (e) {
        debugPrint('Raw data submission failed: $e');
      }
      
      // Method 2: Try HTTP form submission as fallback
      debugPrint('CUPS: Trying HTTP form submission to http://$ipAddress:$port/printers/$printerName');
      try {
        final url = 'http://$ipAddress:$port/printers/$printerName';
        
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'multipart/form-data; boundary=----WebKitFormBoundary',
          },
          body: _createMultipartBody(data, printerName),
        );

        debugPrint('CUPS Form Response: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          debugPrint('CUPS: HTTP form submission successful');
          return true;
        }
      } catch (e) {
        debugPrint('HTTP form submission failed: $e');
      }
      
      // Method 2: Try direct socket connection to printer port 9100
      debugPrint('CUPS: Trying direct socket to printer port 9100');
      try {
        final socket = await Socket.connect(ipAddress, 9100, timeout: Duration(seconds: 5));
        socket.add(data);
        await socket.flush();
        await socket.close();
        debugPrint('Direct socket print: Success');
        return true;
      } catch (e) {
        debugPrint('Direct socket failed: $e');
      }
      
      // Method 3: Try using lp command as fallback (for Unix/Linux systems)
      debugPrint('CUPS: Trying lp command as fallback');
      
      try {
        // Save data to temporary file and use lp command
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/flutter_print_${DateTime.now().millisecondsSinceEpoch}.raw');
        await tempFile.writeAsBytes(data);
        
        debugPrint('Temp file created: ${tempFile.path}');
        
        final result = await Process.run('lp', [
          '-d', printerName,
          '-t', 'Flutter Print Job',
          tempFile.path
        ]);
        
        debugPrint('lp command result: ${result.exitCode}');
        debugPrint('lp stdout: ${result.stdout}');
        debugPrint('lp stderr: ${result.stderr}');
        
        // Clean up temp file
        await tempFile.delete();
        
        if (result.exitCode == 0) {
          debugPrint('CUPS: lp command successful');
          return true;
        }
      } catch (e) {
        debugPrint('lp command failed: $e');
      }
      
      return false;
      
    } catch (e) {
      debugPrint('CUPS Error: $e');
      return false;
    }
  }

  Future<bool> _printViaRawTCP(Uint8List data) async {
    try {
      final socket = await Socket.connect(ipAddress, port, timeout: Duration(seconds: 10));
      socket.add(data);
      await socket.flush();
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  Uint8List _createMultipartBody(Uint8List printData, String printerName) {
    final boundary = '----WebKitFormBoundary';
    final List<int> body = [];
    
    // Add form fields for CUPS job submission
    body.addAll(utf8.encode('--$boundary\r\n'));
    body.addAll(utf8.encode('Content-Disposition: form-data; name="OP"\r\n\r\n'));
    body.addAll(utf8.encode('print-file'));
    body.addAll(utf8.encode('\r\n'));
    
    body.addAll(utf8.encode('--$boundary\r\n'));
    body.addAll(utf8.encode('Content-Disposition: form-data; name="job_name"\r\n\r\n'));
    body.addAll(utf8.encode('Flutter Print Job'));
    body.addAll(utf8.encode('\r\n'));
    
    body.addAll(utf8.encode('--$boundary\r\n'));
    body.addAll(utf8.encode('Content-Disposition: form-data; name="job_priority"\r\n\r\n'));
    body.addAll(utf8.encode('50'));
    body.addAll(utf8.encode('\r\n'));
    
    body.addAll(utf8.encode('--$boundary\r\n'));
    body.addAll(utf8.encode('Content-Disposition: form-data; name="job_hold_until"\r\n\r\n'));
    body.addAll(utf8.encode('no-hold'));
    body.addAll(utf8.encode('\r\n'));
    
    // Add file data
    body.addAll(utf8.encode('--$boundary\r\n'));
    body.addAll(utf8.encode('Content-Disposition: form-data; name="file"; filename="print_data.raw"\r\n'));
    body.addAll(utf8.encode('Content-Type: application/octet-stream\r\n\r\n'));
    body.addAll(printData);
    body.addAll(utf8.encode('\r\n'));
    
    body.addAll(utf8.encode('--$boundary--\r\n'));
    
    return Uint8List.fromList(body);
  }

  Uint8List _createProperIPPRequest(Uint8List printData) {
    // Create a more complete IPP Print-Job request
    final List<int> request = [];
    
    // IPP version 2.0
    request.addAll([2, 0]); // Major, Minor version
    
    // Operation ID (Print-Job = 2)
    request.addAll([0, 2]); // Big endian
    
    // Request ID
    request.addAll([0, 0, 0, 1]); // Big endian
    
    // Attribute groups
    // Operation attributes tag
    request.add(0x01); // operation-attributes-tag
    
    // charset
    request.addAll([0x47, 0x00, 0x12]); // charset tag, length
    request.addAll(utf8.encode('attributes-charset'));
    request.addAll([0x47, 0x00, 0x05]); // charset tag, length
    request.addAll(utf8.encode('utf-8'));
    
    // natural-language
    request.addAll([0x48, 0x00, 0x1B]); // natural-language tag, length
    request.addAll(utf8.encode('attributes-natural-language'));
    request.addAll([0x48, 0x00, 0x02]); // natural-language tag, length
    request.addAll(utf8.encode('en'));
    
    // printer-uri
    request.addAll([0x45, 0x00, 0x0B]); // uri tag, length
    request.addAll(utf8.encode('printer-uri'));
    final printerUri = 'ipp://$ipAddress:$port/printers/${printerName ?? "default"}';
    final printerUriBytes = utf8.encode(printerUri);
    request.addAll([(printerUriBytes.length >> 8) & 0xFF, printerUriBytes.length & 0xFF]); // length big endian
    request.addAll(printerUriBytes);
    
    // job-name
    request.addAll([0x42, 0x00, 0x08]); // nameWithoutLanguage tag, length
    request.addAll(utf8.encode('job-name'));
    request.addAll([0x42, 0x00, 0x0C]); // nameWithoutLanguage tag, length
    request.addAll(utf8.encode('Flutter Print'));
    
    // End of attributes
    request.add(0x03); // end-of-attributes-tag
    
    // Add print data
    request.addAll(printData);
    
    return Uint8List.fromList(request);
  }

  Uint8List _createIPPRequest(Uint8List printData) {
    // Simple IPP Print-Job request
    final buffer = ByteData(8 + printData.length);
    
    // IPP version 2.0
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

class NetworkPrinterCompletePage extends StatefulWidget {
  final TrxModel trx;
  final bool isPostpaid;
  final Uint8List? customReceiptData; // Add parameter for custom receipt data

  const NetworkPrinterCompletePage({
    Key? key, 
    required this.trx, 
    this.isPostpaid = false,
    this.customReceiptData, // Optional custom receipt data
  }) : super(key: key);

  @override
  _NetworkPrinterCompletePageState createState() => _NetworkPrinterCompletePageState();
}

class _NetworkPrinterCompletePageState extends State<NetworkPrinterCompletePage> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _printerNameController = TextEditingController();
  
  bool _isLoading = false;
  String _status = 'Ready';
  NetworkPrinterComplete? _printer;

  @override
  void initState() {
    super.initState();
    _portController.text = '631'; // Default to CUPS port
    _ipController.text = '192.168.0.100';
    _printerNameController.text = 'default';
  }

  Future<void> _testConnection() async {
    if (_ipController.text.isEmpty) {
      _showError('IP Address harus diisi');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Testing connection...';
    });

    try {
      _printer = NetworkPrinterComplete(
        ipAddress: _ipController.text,
        port: int.tryParse(_portController.text) ?? 9100,
        printerName: _printerNameController.text.isNotEmpty ? _printerNameController.text : null,
      );

      bool isConnected = await _printer!.testConnection();
      
      setState(() {
        _isLoading = false;
        _status = isConnected ? 'Connection successful!' : 'Connection failed';
      });

      if (isConnected) {
        _showSuccess('Printer berhasil terhubung!');
      } else {
        _showError('Gagal terhubung ke printer');
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
      Uint8List printData;
      
      // Use custom receipt data if available (from printPreviewSby)
      if (widget.customReceiptData != null) {
        printData = widget.customReceiptData!;
        debugPrint('✅ Using custom receipt data from printPreviewSby, size: ${printData.length} bytes');
        
        if (printData.isEmpty) {
          debugPrint('❌ Error: Custom receipt data is empty');
          _showError('Data struk kosong');
          return;
        }
      } else {
        // Generate print data using ESC/POS (similar to v1 method in original code)
        debugPrint('✅ Generating print data for transaction: ${widget.trx.id}');
        
        // Validate data first
        if (widget.trx == null) {
          debugPrint('❌ Error: Transaction data is null');
          _showError('Data transaksi tidak tersedia');
          return;
        }
        
        if (bloc.user.valueWrapper?.value == null) {
          debugPrint('❌ Error: User data is null');
          _showError('Data user tidak tersedia');
          return;
        }
        
        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm58, profile);
      
        List<int> bytes = [];
        
        // Header
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
            width: PosTextSize.size2,
            height: PosTextSize.size2,
          ),
        );
        
        bytes += generator.text(
          bloc.user.valueWrapper?.value?.alamatToko?.isEmpty == true
              ? bloc.user.valueWrapper?.value?.alamat ?? ''
              : bloc.user.valueWrapper?.value?.alamatToko ?? '',
          styles: PosStyles(
            align: PosAlign.center,
            width: PosTextSize.size1,
            height: PosTextSize.size1,
          ),
          linesAfter: 1,
        );
        
        // Date and Transaction ID
        bytes += generator.text(
          formatDate(widget.trx.created_at, 'dd MMMM yyyy HH:mm:ss'),
          styles: PosStyles(
            width: PosTextSize.size1,
            height: PosTextSize.size1,
          ),
        );
        
        bytes += generator.text(
          'TrxID: ${widget.trx.id.toUpperCase()}',
          styles: PosStyles(
            width: PosTextSize.size1,
            height: PosTextSize.size1,
          ),
        );
        
        bytes += generator.hr();
        
        // Transaction details
        bytes += generator.text(
          'Transaksi:',
          styles: PosStyles(
            underline: true,
            width: PosTextSize.size1,
            height: PosTextSize.size1,
          ),
        );
        
        bytes += _printLine(generator, 'Nama Produk', widget.trx.produk['nama']);
        bytes += _printLine(generator, 'Tujuan', widget.trx.tujuan);
        
        // Additional print data
        widget.trx.print.forEach((el) {
          if (!['token', 'jumlah', 'nominal', 'tagihan', 'admin']
              .contains(el['label'].toString().toLowerCase())) {
            bytes += _printLine(generator, el['label'], el['value']);
          }
        });
        
        // Token section
        if (widget.trx.print.isNotEmpty) {
          bytes += generator.hr();
          widget.trx.print.forEach((el) {
            if (el['label'].toString().toLowerCase() == 'token') {
              bytes += generator.text(
                el['value'].toString(),
                styles: PosStyles(
                  bold: true,
                  align: PosAlign.center,
                  width: PosTextSize.size2,
                  height: PosTextSize.size2,
                ),
              );
            }
          });
        }
        
        bytes += generator.hr();
        
        // Total
        bytes += _printLine(generator, 'Total', 'Rp ${widget.trx.harga_jual}', bold: true);
        
        bytes += generator.hr();
        
        // Footer
        bytes += generator.text(
          'STRUK INI MERUPAKAN BUKTI PEMBAYARAN YANG SAH',
          styles: PosStyles(
            align: PosAlign.center,
            width: PosTextSize.size1,
            height: PosTextSize.size1,
          ),
          linesAfter: 1,
        );
        
        bytes += generator.text(
          'TERSEDIA PULSA, KUOTA ALL OPERATOR, TOKEN PLN, BAYAR TAGIHAN LISTRIK, PDAM, TELKOM, ITEM GAME, DAN MULTI PEMBAYARAN LAINNYA',
          styles: PosStyles(
            align: PosAlign.center,
            width: PosTextSize.size1,
            height: PosTextSize.size1,
          ),
          linesAfter: 3,
        );

        printData = Uint8List.fromList(bytes);
      }
      
      bool success = await _printer!.print(printData);

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

  List<int> _printLine(Generator generator, String label, dynamic value, {bool bold = false}) {
    List<int> bytes = [];
    bytes += generator.text(
      '$label: $value',
      styles: PosStyles(
        bold: bold,
        width: PosTextSize.size1,
        height: PosTextSize.size1,
      ),
    );
    return bytes;
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
        title: Text('Network Printer - Print Receipt'),
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
                        hintText: '192.168.0.100',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.computer),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _portController,
                      decoration: InputDecoration(
                        labelText: 'Port',
                        hintText: '9100',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.settings_ethernet),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _printerNameController,
                      decoration: InputDecoration(
                        labelText: 'Printer Name (CUPS)',
                        hintText: 'default',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.print),
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
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _testConnection,
                            icon: _isLoading 
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Icon(Icons.wifi_find),
                            label: Text('Test Connection'),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading || _printer == null ? null : _printReceipt,
                            icon: Icon(Icons.print),
                            label: Text('Print Receipt'),
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
    super.dispose();
  }
} 
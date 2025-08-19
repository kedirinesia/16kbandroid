import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:mobile/bloc/Bloc.dart' show bloc;
import 'package:mobile/models/trx.dart';
import 'package:mobile/screen/custom_alert_dialog.dart';

class NetworkPrinter {
  final String ipAddress;
  final int port;

  NetworkPrinter({
    required this.ipAddress,
    this.port = 9100, // Default port for most thermal printers
  });

  // Test connection to printer
  Future<bool> testConnection() async {
    try {
      final socket = await Socket.connect(ipAddress, port, timeout: Duration(seconds: 5));
      await socket.close();
  
      return true;
    } catch (e) {
  
      return false;
    }
  }

  // Print using raw TCP connection
  Future<bool> print(Uint8List data) async {
    try {
      final socket = await Socket.connect(ipAddress, port, timeout: Duration(seconds: 10));
      
      // Send print data
      socket.add(data);
      await socket.flush();
      await socket.close();
      
    
      return true;
    } catch (e) {
      
      return false;
    }
  }
}

class NetworkPrinterPage extends StatefulWidget {
  final TrxModel trx;
  final bool isPostpaid;

  const NetworkPrinterPage({Key? key, required this.trx, this.isPostpaid = false}) : super(key: key);

  @override
  _NetworkPrinterPageState createState() => _NetworkPrinterPageState();
}

class _NetworkPrinterPageState extends State<NetworkPrinterPage> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  
  bool _isLoading = false;
  String _status = 'Ready';
  NetworkPrinter? _printer;

  @override
  void initState() {
    super.initState();
    _portController.text = '9100'; // Default port for thermal printers
    _loadSavedSettings();
  }

  void _loadSavedSettings() {
    // Load saved printer settings
    _ipController.text = '192.168.1.100'; // Default IP
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
      _printer = NetworkPrinter(
        ipAddress: _ipController.text,
        port: int.tryParse(_portController.text) ?? 9100,
      );

      bool isConnected = await _printer!.testConnection();
      
      setState(() {
        _isLoading = false;
        _status = isConnected ? 'Connection successful!' : 'Connection failed';
      });

      if (isConnected) {
        _showSuccess('Printer berhasil terhubung!');
      } else {
        _showError('Gagal terhubung ke printer. Periksa IP address dan port.');
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
      // Generate print data using ESC/POS
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      
      List<int> bytes = [];
      
      // Header
      bytes += generator.text(
        bloc.user.valueWrapper?.value?.namaToko?.isEmpty == true
            ? bloc.user.valueWrapper?.value?.nama ?? ''
            : bloc.user.valueWrapper?.value?.namaToko ?? '',
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
        '${widget.trx.created_at}',
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

      final printData = Uint8List.fromList(bytes);
      
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
        title: Text('Network Printer Setup'),
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
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tips:',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '• Port 9100: Thermal printer standar\n'
                            '• Port 631: CUPS printer\n'
                            '• Port 515: LPR printer\n'
                            '• Pastikan printer dan device dalam jaringan yang sama',
                            style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                          ),
                        ],
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
    super.dispose();
  }
} 
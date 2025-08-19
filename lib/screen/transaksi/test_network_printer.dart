import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';

class NetworkPrinterTestPage extends StatefulWidget {
  @override
  _NetworkPrinterTestPageState createState() => _NetworkPrinterTestPageState();
}

class _NetworkPrinterTestPageState extends State<NetworkPrinterTestPage> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  
  bool _isLoading = false;
  String _status = 'Ready';
  List<String> _logMessages = [];

  @override
  void initState() {
    super.initState();
    _portController.text = '9100';
    _ipController.text = '192.168.1.100';
  }

  void _addLog(String message) {
    setState(() {
      _logMessages.add('${DateTime.now().toString().substring(11, 19)}: $message');
      if (_logMessages.length > 20) {
        _logMessages.removeAt(0);
      }
    });
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

    _addLog('Testing connection to ${_ipController.text}:${_portController.text}');

    try {
      final socket = await Socket.connect(
        _ipController.text, 
        int.tryParse(_portController.text) ?? 9100,
        timeout: Duration(seconds: 5)
      );
      
      await socket.close();
      
      setState(() {
        _isLoading = false;
        _status = 'Connection successful!';
      });
      
      _addLog('Connection test: SUCCESS');
      _showSuccess('Printer berhasil terhubung!');
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Connection failed: $e';
      });
      
      _addLog('Connection test: FAILED - $e');
      _showError('Gagal terhubung: $e');
    }
  }

  Future<void> _testPrint() async {
    if (_ipController.text.isEmpty) {
      _showError('IP Address harus diisi');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Testing print...';
    });

    _addLog('Testing print to ${_ipController.text}:${_portController.text}');

    try {
      // Generate test print data
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      
      List<int> bytes = [];
      bytes += generator.text(
        'TEST PRINT',
        styles: PosStyles(
          bold: true,
          align: PosAlign.center,
          width: PosTextSize.size2,
          height: PosTextSize.size2,
        ),
      );
      bytes += generator.text(
        'Network Printer Test',
        styles: PosStyles(
          align: PosAlign.center,
          width: PosTextSize.size1,
          height: PosTextSize.size1,
        ),
        linesAfter: 1,
      );
      bytes += generator.text(
        'Date: ${DateTime.now().toString().substring(0, 19)}',
        styles: PosStyles(
          width: PosTextSize.size1,
          height: PosTextSize.size1,
        ),
      );
      bytes += generator.text(
        'IP: ${_ipController.text}',
        styles: PosStyles(
          width: PosTextSize.size1,
          height: PosTextSize.size1,
        ),
      );
      bytes += generator.text(
        'Port: ${_portController.text}',
        styles: PosStyles(
          width: PosTextSize.size1,
          height: PosTextSize.size1,
        ),
      );
      bytes += generator.hr();
      bytes += generator.text(
        'If you can see this,',
        styles: PosStyles(
          align: PosAlign.center,
          width: PosTextSize.size1,
          height: PosTextSize.size1,
        ),
      );
      bytes += generator.text(
        'network printer is working!',
        styles: PosStyles(
          align: PosAlign.center,
          width: PosTextSize.size1,
          height: PosTextSize.size1,
        ),
      );
      bytes += generator.hr();
      bytes += generator.text(
        'SUCCESS',
        styles: PosStyles(
          bold: true,
          align: PosAlign.center,
          width: PosTextSize.size2,
          height: PosTextSize.size2,
        ),
      );
      bytes += generator.feed(3);

      final printData = Uint8List.fromList(bytes);
      
      // Send to printer
      final socket = await Socket.connect(
        _ipController.text, 
        int.tryParse(_portController.text) ?? 9100,
        timeout: Duration(seconds: 10)
      );
      
      socket.add(printData);
      await socket.flush();
      await socket.close();
      
      setState(() {
        _isLoading = false;
        _status = 'Print test successful!';
      });
      
      _addLog('Print test: SUCCESS');
      _showSuccess('Test print berhasil dikirim!');
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Print test failed: $e';
      });
      
      _addLog('Print test: FAILED - $e');
      _showError('Gagal mengirim test print: $e');
    }
  }

  Future<void> _pingTest() async {
    if (_ipController.text.isEmpty) {
      _showError('IP Address harus diisi');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Pinging...';
    });

    _addLog('Pinging ${_ipController.text}');

    try {
      final result = await Process.run('ping', ['-c', '3', _ipController.text]);
      
      setState(() {
        _isLoading = false;
        _status = result.exitCode == 0 ? 'Ping successful!' : 'Ping failed';
      });
      
      if (result.exitCode == 0) {
        _addLog('Ping test: SUCCESS');
        _showSuccess('Ping berhasil! Printer dapat diakses.');
      } else {
        _addLog('Ping test: FAILED');
        _showError('Ping gagal. Printer tidak dapat diakses.');
      }
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Ping error: $e';
      });
      
      _addLog('Ping test: ERROR - $e');
      _showError('Error saat ping: $e');
    }
  }

  void _clearLog() {
    setState(() {
      _logMessages.clear();
    });
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Network Printer Test'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: _clearLog,
            tooltip: 'Clear Log',
          ),
        ],
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
                            onPressed: _isLoading ? null : _pingTest,
                            icon: Icon(Icons.radar),
                            label: Text('Ping'),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _testConnection,
                            icon: Icon(Icons.wifi_find),
                            label: Text('Test Connection'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _testPrint,
                      icon: Icon(Icons.print),
                      label: Text('Test Print'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Log Messages',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_logMessages.length} messages',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        padding: EdgeInsets.all(8),
                        itemCount: _logMessages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              _logMessages[index],
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          );
                        },
                      ),
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
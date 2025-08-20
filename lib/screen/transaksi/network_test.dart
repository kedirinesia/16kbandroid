import 'dart:io';
import 'package:flutter/material.dart';

class NetworkTestPage extends StatefulWidget {
  const NetworkTestPage({Key? key}) : super(key: key);

  @override
  _NetworkTestPageState createState() => _NetworkTestPageState();
}

class _NetworkTestPageState extends State<NetworkTestPage> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  
  bool _isLoading = false;
  String _status = 'Ready';

  @override
  void initState() {
    super.initState();
    _portController.text = '9100';
    _ipController.text = '192.168.0.100';
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
      
      _showSuccess('Printer berhasil terhubung!');
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Connection failed: $e';
      });
      
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

    try {
      final socket = await Socket.connect(
        _ipController.text, 
        int.tryParse(_portController.text) ?? 9100,
        timeout: Duration(seconds: 10)
      );
      
      // Simple test print data (ESC/POS commands)
      final testData = [
        0x1B, 0x40, // Initialize printer
        0x1B, 0x61, 0x01, // Center alignment
        0x54, 0x45, 0x53, 0x54, 0x20, 0x50, 0x52, 0x49, 0x4E, 0x54, // "TEST PRINT"
        0x0A, 0x0A, // New lines
        0x1B, 0x61, 0x00, // Left alignment
        0x54, 0x68, 0x69, 0x73, 0x20, 0x69, 0x73, 0x20, 0x61, 0x20, 0x74, 0x65, 0x73, 0x74, // "This is a test"
        0x0A, 0x0A, 0x0A, // New lines
      ];
      
      socket.add(testData);
      await socket.flush();
      await socket.close();
      
      setState(() {
        _isLoading = false;
        _status = 'Print test successful!';
      });
      
      _showSuccess('Test print berhasil dikirim!');
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Print test failed: $e';
      });
      
      _showError('Gagal mengirim test print: $e');
    }
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
                            onPressed: _isLoading ? null : _testPrint,
                            icon: Icon(Icons.print),
                            label: Text('Test Print'),
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
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class BluetoothTestPage extends StatefulWidget {
  @override
  _BluetoothTestPageState createState() => _BluetoothTestPageState();
}

class _BluetoothTestPageState extends State<BluetoothTestPage> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> devices = [];
  bool isLoading = false;
  String status = 'Ready';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      status = 'Checking permissions...';
    });

    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.locationWhenInUse,
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
      ].request();

      print('Permission Status:');
      statuses.forEach((permission, status) {
        print('${permission}: $status');
      });

      setState(() {
        var locationStatus = statuses[Permission.locationWhenInUse];
        var bluetoothStatus = statuses[Permission.bluetooth] ?? 'Unknown';
        status = 'Permissions checked. Location: $locationStatus, Bluetooth: $bluetoothStatus';
      });
    } catch (e) {
      setState(() {
        status = 'Error checking permissions: $e';
      });
    }
  }

  Future<void> _checkBluetoothStatus() async {
    setState(() {
      status = 'Checking Bluetooth status...';
    });

    try {
      bool? isOn = await bluetooth.isOn;
      setState(() {
        status = 'Bluetooth is ${isOn == true ? 'ON' : 'OFF'}';
      });
    } catch (e) {
      setState(() {
        status = 'Error checking Bluetooth: $e';
      });
    }
  }

  Future<void> _scanDevices() async {
    setState(() {
      isLoading = true;
      status = 'Scanning for devices...';
    });

    try {
      List<BluetoothDevice> bondedDevices = await bluetooth.getBondedDevices();
      
      setState(() {
        devices = bondedDevices;
        isLoading = false;
        status = 'Found ${bondedDevices.length} bonded devices';
      });

      print('Found devices:');
      for (var device in bondedDevices) {
        print('- ${device.name} (${device.address})');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        status = 'Error scanning devices: $e';
      });
      print('Error: $e');
    }
  }

  Future<void> _testConnection(BluetoothDevice device) async {
    setState(() {
      status = 'Testing connection to ${device.name}...';
    });

    try {
      bool? isConnected = await bluetooth.isConnected;
      if (isConnected == true) {
        await bluetooth.disconnect();
      }

      await bluetooth.connect(device);
      setState(() {
        status = 'Connected to ${device.name}';
      });

      // Test simple print
      await bluetooth.printCustom('Test Print from iOS', 0, 0);
      await bluetooth.printNewLine();
      await bluetooth.printNewLine();

      await bluetooth.disconnect();
      setState(() {
        status = 'Test completed successfully';
      });
    } catch (e) {
      setState(() {
        status = 'Connection test failed: $e';
      });
      print('Connection error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Test - iOS'),
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
                      'Status:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(status),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _checkPermissions,
                            child: Text('Check Permissions'),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _checkBluetoothStatus,
                            child: Text('Check Bluetooth'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: isLoading ? null : _scanDevices,
                      child: isLoading 
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Scan Devices'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Found Devices:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Expanded(
              child: devices.isEmpty
                ? Center(
                    child: Text(
                      'No devices found. Tap "Scan Devices" to search.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      BluetoothDevice device = devices[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(Icons.print),
                          title: Text(device.name ?? 'Unknown Device'),
                          subtitle: Text(device.address ?? 'Unknown Address'),
                          trailing: ElevatedButton(
                            onPressed: () => _testConnection(device),
                            child: Text('Test'),
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
} 
import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothService {
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;

  // Printer service and characteristic UUIDs
  // Note: These are generic examples and may need to be adjusted for your specific printer
  static const String PRINTER_SERVICE_UUID = '000018f0-0000-1000-8000-00805f9b34fb';
  static const String PRINTER_CHARACTERISTIC_UUID = '00002af1-0000-1000-8000-00805f9b34fb';

  // Check if the device is connected to a printer
  Future<bool> isConnected() async {
    final connectedDevices = await flutterBlue.connectedDevices;
    final prefs = await SharedPreferences.getInstance();
    final savedDeviceId = prefs.getString('printerDeviceId');
    
    if (savedDeviceId != null) {
      for (var device in connectedDevices) {
        if (device.id.id == savedDeviceId) {
          _connectedDevice = device;
          await _discoverServices();
          return _writeCharacteristic != null;
        }
      }
    }
    
    return false;
  }

  // Get the connected device name
  String? getConnectedDeviceName() {
    return _connectedDevice?.name;
  }

  // Request necessary permissions
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.location,
    ].request();
    
    return statuses[Permission.bluetooth]!.isGranted &&
           statuses[Permission.location]!.isGranted;
  }

  // Scan for nearby Bluetooth devices
  Future<List<BluetoothDevice>> scanForDevices() async {
    // Ensure permissions are granted
    bool hasPermissions = await requestPermissions();
    if (!hasPermissions) {
      throw Exception('Bluetooth and Location permissions are required');
    }
    
    // Start scanning
    List<BluetoothDevice> devicesList = [];
    
    // Listen for scan results
    StreamSubscription<List<ScanResult>>? scanSubscription;
    scanSubscription = flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (!devicesList.contains(r.device)) {
          devicesList.add(r.device);
        }
      }
    });
    
    // Start the scan
    await flutterBlue.startScan(timeout: Duration(seconds: 5));
    
    // Wait for scan to complete
    await Future.delayed(Duration(seconds: 5));
    
    // Stop scanning
    await flutterBlue.stopScan();
    await scanSubscription.cancel();
    
    return devicesList;
  }

  // Connect to a selected printer
  Future<bool> connectToPrinter(BluetoothDevice device) async {
    try {
      await device.connect();
      _connectedDevice = device;
      
      // Save device ID to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('printerDeviceId', device.id.id);
      await prefs.setString('printerDeviceName', device.name);
      
      // Discover services and get the write characteristic
      bool success = await _discoverServices();
      
      return success;
    } catch (e) {
      print('Error connecting to printer: $e');
      return false;
    }
  }

  // Disconnect from the current printer
  Future<bool> disconnectPrinter() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
        _writeCharacteristic = null;
        
        // Clear saved device info
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('printerDeviceId');
        await prefs.remove('printerDeviceName');
      }
      return true;
    } catch (e) {
      print('Error disconnecting printer: $e');
      return false;
    }
  }

  // Discover services and find the write characteristic
  Future<bool> _discoverServices() async {
    if (_connectedDevice == null) return false;
    
    try {
      List<BluetoothService> services = await _connectedDevice!.discoverServices();
      
      for (BluetoothService service in services) {
        if (service.uuid.toString() == PRINTER_SERVICE_UUID) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString() == PRINTER_CHARACTERISTIC_UUID) {
              _writeCharacteristic = characteristic;
              return true;
            }
          }
        }
      }
      
      return false;
    } catch (e) {
      print('Error discovering services: $e');
      return false;
    }
  }

  // Print a label
  Future<bool> printLabel(Map<String, dynamic> data) async {
    if (_writeCharacteristic == null || _connectedDevice == null) {
      return false;
    }
    
    try {
      // Generate PRN command
      final prn = generatePrn(data);
      
      // Convert to bytes
      final bytes = utf8.encode(prn);
      
      // Send in chunks to avoid buffer overflow
      const int CHUNK_SIZE = 20;
      for (var i = 0; i < bytes.length; i += CHUNK_SIZE) {
        final end = (i + CHUNK_SIZE < bytes.length) ? i + CHUNK_SIZE : bytes.length;
        final chunk = bytes.sublist(i, end);
        
        await _writeCharacteristic!.write(chunk);
        
        // Small delay between chunks
        await Future.delayed(Duration(milliseconds: 50));
      }
      
      return true;
    } catch (e) {
      print('Error printing label: $e');
      return false;
    }
  }

  // Generate a printer command
  String generatePrn(Map<String, dynamic> data) {
    // Extract data
    final devoteeId = data['devotee_id'] ?? '';
    final devoteeName = data['devotee_name'] ?? '';
    final item = data['item'] ?? '';
    final date = data['date'] ?? '';
    
    // Create a PRN command for the printer
    // This is a simple example; adjust according to your printer's specifications
    return '''
N
D11
B50,20,0,1,2,8,40,B,"$devoteeId"
A60,70,0,3,1,1,N,"$devoteeName"
A60,100,0,3,1,1,N,"Item: $item"
A60,130,0,2,1,1,N,"Date: $date"
P1
''';
  }
}
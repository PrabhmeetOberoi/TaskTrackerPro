import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/bluetooth_service.dart';
import '../widgets/numeric_keypad.dart';

class DevoteeScreen extends StatefulWidget {
  const DevoteeScreen({Key? key}) : super(key: key);

  @override
  _DevoteeScreenState createState() => _DevoteeScreenState();
}

class _DevoteeScreenState extends State<DevoteeScreen> {
  final _apiService = ApiService();
  final _bluetoothService = BluetoothService();
  final TextEditingController _devoteeIdController = TextEditingController();
  
  bool _isLoading = false;
  bool _isPrinterConnected = false;
  Map<String, dynamic>? _selectedItem;
  
  @override
  void initState() {
    super.initState();
    _checkPrinterConnection();
  }
  
  Future<void> _checkPrinterConnection() async {
    final isConnected = await _bluetoothService.isConnected();
    setState(() {
      _isPrinterConnected = isConnected;
    });
  }
  
  void _addDigit(String digit) {
    setState(() {
      _devoteeIdController.text += digit;
    });
  }
  
  void _clearDigit() {
    setState(() {
      if (_devoteeIdController.text.isNotEmpty) {
        _devoteeIdController.text = _devoteeIdController.text.substring(
          0, _devoteeIdController.text.length - 1
        );
      }
    });
  }
  
  void _clearAll() {
    setState(() {
      _devoteeIdController.text = '';
    });
  }
  
  Future<void> _submitDevoteeId() async {
    if (_devoteeIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Devotee ID')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _selectedItem = null;
    });
    
    try {
      final result = await _apiService.checkInDevotee(_devoteeIdController.text);
      
      setState(() {
        _isLoading = false;
        _selectedItem = result;
      });
      
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Devotee ID not found')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  Future<void> _scanAndConnectPrinter() async {
    try {
      // Request permissions
      final hasPermissions = await _bluetoothService.requestPermissions();
      if (!hasPermissions) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth and Location permissions are required')),
        );
        return;
      }
      
      // Show scanning dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scanning for devices...')),
      );
      
      // Scan for devices
      final devices = await _bluetoothService.scanForDevices();
      
      if (!mounted) return;
      
      if (devices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No devices found')),
        );
        return;
      }
      
      // Show device selection dialog
      final selectedDevice = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Printer'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return ListTile(
                  title: Text(device.name.isNotEmpty ? device.name : 'Unknown Device'),
                  subtitle: Text(device.id.id),
                  onTap: () => Navigator.pop(context, device),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      
      if (selectedDevice != null) {
        // Show connecting dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connecting to ${selectedDevice.name}...')),
        );
        
        // Connect to selected device
        final connected = await _bluetoothService.connectToPrinter(selectedDevice);
        
        setState(() {
          _isPrinterConnected = connected;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              connected
                  ? 'Connected to ${selectedDevice.name}'
                  : 'Failed to connect to ${selectedDevice.name}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  Future<void> _printLabel() async {
    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No item selected to print')),
      );
      return;
    }
    
    if (!_isPrinterConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect a printer first')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _bluetoothService.printLabel(_selectedItem!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Label sent to printer'
                : 'Failed to send label to printer',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devotee Check-in'),
      ),
      drawer: _buildDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Devotee Check-in',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Enter your Devotee ID below to check in and receive a random item.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _devoteeIdController,
                      decoration: InputDecoration(
                        labelText: 'Devotee ID',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                      readOnly: true, // Use keypad instead of keyboard
                    ),
                    const SizedBox(height: 24),
                    
                    // Custom Keypad
                    NumericKeypad(
                      onKeyPressed: _addDigit,
                      onClear: _clearAll,
                      onBackspace: _clearDigit,
                    ),
                    
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitDevoteeId,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : const Text('Submit', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (_selectedItem != null) ...[
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Item Selection Result',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Icon(
                        Icons.card_giftcard,
                        size: 64,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Devotee: ${_selectedItem!['devotee_name']}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${_selectedItem!['devotee_id']}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Date: ${_selectedItem!['date']}',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${_selectedItem!['item']}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.print),
                          label: const Text('Print Label', style: TextStyle(fontSize: 18)),
                          onPressed: _isLoading ? null : _printLabel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Printer Status:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _isPrinterConnected
                      ? 'Connected'
                      : 'No printer connected',
                  style: TextStyle(
                    color: _isPrinterConnected
                        ? Colors.green[100]
                        : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.print),
            title: const Text('Connect Printer'),
            onTap: () {
              Navigator.pop(context);
              _scanAndConnectPrinter();
            },
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home Page'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
          if (_isPrinterConnected)
            ListTile(
              leading: const Icon(Icons.bluetooth_disabled),
              title: const Text('Disconnect Printer'),
              onTap: () async {
                final disconnected = await _bluetoothService.disconnectPrinter();
                
                setState(() {
                  _isPrinterConnected = !disconnected;
                });
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      disconnected
                          ? 'Printer disconnected'
                          : 'Failed to disconnect printer',
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _devoteeIdController.dispose();
    super.dispose();
  }
}
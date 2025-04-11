import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_blue/flutter_blue.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';

// Base URL for the API (change this to your server's URL)
const String baseUrl = 'http://localhost:5000';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TempleApp());
}

class TempleApp extends StatelessWidget {
  const TempleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Temple Management System',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/admin-setup': (context) => const AdminSetupPage(),
        '/devotee': (context) => const DevoteePage(),
        '/dashboard': (context) => const DashboardPage(),
        '/add-devotee': (context) => const AddDevoteePage(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAppActivation();
  }

  Future<void> _checkAppActivation() async {
    try {
      // Check if app is activated (has admin account)
      final response = await http.get(Uri.parse('$baseUrl/'));
      
      // If redirected to admin-setup, app is not activated
      if (response.request?.url.path.contains('admin_setup') ?? false) {
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/admin-setup');
        });
      } else {
        // App is activated, go to home
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/home');
        });
      }
    } catch (e) {
      // Handle offline case or server down
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server connection failed: $e')),
      );
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacementNamed(context, '/home');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.temple_hindu,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              'Temple Management System',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoggedIn = false;
  
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }
  
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Temple Management System'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.temple_hindu,
              size: 80,
              color: Colors.indigo,
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to Temple Management System',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'This application helps manage temple devotees and their visits.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.person),
                  label: const Text('Devotee Page'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/devotee');
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.dashboard),
                  label: const Text('Dashboard'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    backgroundColor: Colors.indigo[300],
                  ),
                  onPressed: _isLoggedIn
                      ? () {
                          Navigator.pushNamed(context, '/dashboard');
                        }
                      : () {
                          Navigator.pushNamed(context, '/login');
                        },
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (!_isLoggedIn)
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text('Login as Admin'),
              ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/login'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'username': _usernameController.text,
            'password': _passwordController.text,
          },
        );
        
        if (response.statusCode == 200) {
          // Check if login was successful or not
          if (response.request?.url.path == '/home' || 
              response.request?.url.path == '/index' || 
              response.request?.url.path == '/') {
            // Successfully logged in
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isLoggedIn', true);
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Login successful')),
            );
            
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else {
            // Login failed
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid username or password')),
            );
          }
        } else {
          // Handle error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed: ${response.statusCode}')),
          );
        }
      } catch (e) {
        // Handle connection error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person,
                  size: 80,
                  color: Colors.indigo,
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Text('Login', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class AdminSetupPage extends StatefulWidget {
  const AdminSetupPage({Key? key}) : super(key: key);

  @override
  _AdminSetupPageState createState() => _AdminSetupPageState();
}

class _AdminSetupPageState extends State<AdminSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  
  Future<void> _setupAdmin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/admin_setup'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'username': _usernameController.text,
            'email': _emailController.text,
            'password': _passwordController.text,
            'confirm_password': _confirmPasswordController.text,
          },
        );
        
        if (response.statusCode == 200) {
          // Check if we're redirected to login page
          if (response.request?.url.path == '/login') {
            // Successfully created admin
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Admin account created successfully')),
            );
            
            Navigator.pushReplacementNamed(context, '/login');
          } else {
            // Setup failed
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Admin setup failed')),
            );
          }
        } else {
          // Handle error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Setup failed: ${response.statusCode}')),
          );
        }
      } catch (e) {
        // Handle connection error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Setup'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 80,
                  color: Colors.indigo,
                ),
                const SizedBox(height: 24),
                Text(
                  'Application Setup',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome to the Temple Management System. Let\'s set up your admin account to get started.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                    helperText: 'Choose a username for the admin account',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    if (value.length < 4) {
                      return 'Username must be at least 4 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                    helperText: 'Enter your email address',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                    helperText: 'Choose a strong password (at least 6 characters)',
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _setupAdmin,
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Text('Create Admin Account', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

class DevoteePage extends StatefulWidget {
  const DevoteePage({Key? key}) : super(key: key);

  @override
  _DevoteePageState createState() => _DevoteePageState();
}

class _DevoteePageState extends State<DevoteePage> {
  final _formKey = GlobalKey<FormState>();
  final _devoteeIdController = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = false;
  Map<String, dynamic>? _selectedItem;
  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? _connectedDevice;
  bool _isPrinterConnected = false;
  
  @override
  void initState() {
    super.initState();
    _checkBluetoothPermission();
    _checkConnectedDevice();
  }
  
  Future<void> _checkBluetoothPermission() async {
    var status = await Permission.bluetooth.status;
    if (!status.isGranted) {
      await Permission.bluetooth.request();
    }
    
    status = await Permission.location.status;
    if (!status.isGranted) {
      await Permission.location.request();
    }
  }
  
  Future<void> _checkConnectedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceAddress = prefs.getString('connectedDeviceAddress');
    final deviceName = prefs.getString('connectedDeviceName');
    
    if (deviceAddress != null && deviceName != null) {
      setState(() {
        _isPrinterConnected = true;
      });
    }
  }
  
  Future<void> _scanAndConnectPrinter() async {
    await _checkBluetoothPermission();
    
    // Start scanning
    await flutterBlue.startScan(timeout: Duration(seconds: 4));
    
    // Listen to scan results
    List<BluetoothDevice> devicesList = [];
    
    flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (!devicesList.any((device) => device.id == r.device.id)) {
          devicesList.add(r.device);
        }
      }
    });
    
    // Wait for scan to complete
    await Future.delayed(Duration(seconds: 4));
    await flutterBlue.stopScan();
    
    // Show device selection dialog
    if (mounted) {
      BluetoothDevice? selectedDevice = await showDialog<BluetoothDevice>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Select Bluetooth Printer'),
            content: Container(
              width: double.maxFinite,
              height: 300,
              child: devicesList.isEmpty
                  ? Center(child: Text('No devices found'))
                  : ListView.builder(
                      itemCount: devicesList.length,
                      itemBuilder: (context, index) {
                        BluetoothDevice device = devicesList[index];
                        return ListTile(
                          title: Text(device.name.isNotEmpty
                              ? device.name
                              : 'Unknown Device'),
                          subtitle: Text(device.id.id),
                          onTap: () {
                            Navigator.pop(context, device);
                          },
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancel'),
              ),
            ],
          );
        },
      );
      
      if (selectedDevice != null) {
        // Connect to the selected device
        try {
          await selectedDevice.connect();
          
          // Save the connected device info
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('connectedDeviceAddress', selectedDevice.id.id);
          await prefs.setString('connectedDeviceName', selectedDevice.name);
          
          setState(() {
            _connectedDevice = selectedDevice;
            _isPrinterConnected = true;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connected to ${selectedDevice.name}')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to connect: $e')),
          );
        }
      }
    }
  }
  
  Future<void> _submitDevoteeId() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _selectedItem = null;
      });
      
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/devotee'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'devotee_id': _devoteeIdController.text,
          },
        );
        
        if (response.statusCode == 200) {
          // Parse the response HTML to extract print data
          // This is a simple workaround since we're interacting with a Flask app
          // that returns HTML, not JSON
          final printDataMatch = RegExp(r'data-print-data="([^"]*)"').firstMatch(response.body);
          if (printDataMatch != null && printDataMatch.groupCount >= 1) {
            final encodedData = printDataMatch.group(1)!;
            // Decode HTML entities
            final decodedData = htmlDecode(encodedData);
            // Parse JSON data
            final printData = json.decode(decodedData);
            
            setState(() {
              _selectedItem = printData;
            });
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Item selected: ${printData['item']}')),
            );
          } else {
            // Couldn't extract print data
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to get selected item')),
            );
          }
        } else {
          // Handle error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Request failed: ${response.statusCode}')),
          );
        }
      } catch (e) {
        // Handle connection error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
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
    
    try {
      // In a real application, you would send the data to the printer here
      // This is a simplified example
      
      final prefs = await SharedPreferences.getInstance();
      final deviceAddress = prefs.getString('connectedDeviceAddress');
      
      if (deviceAddress != null) {
        // Generate PRN template
        final prn = _generatePrn(_selectedItem!);
        
        // Here you would actually send the PRN to the printer
        // For now, we'll just show a success message
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Label sent to printer')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Printer not connected')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to print: $e')),
      );
    }
  }
  
  String _generatePrn(Map<String, dynamic> data) {
    // This is a simplified example of a PRN template
    final devoteeId = data['devotee_id'];
    final devoteeName = data['devotee_name'];
    final item = data['item'];
    final date = data['date'];
    
    // Create a sample PRN template
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
  
  // Helper function to decode HTML entities
  String htmlDecode(String input) {
    return input
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#39;', "'");
  }
  
  void _addDigit(String digit) {
    final currentText = _devoteeIdController.text;
    _devoteeIdController.text = currentText + digit;
  }
  
  void _clearDigit() {
    final currentText = _devoteeIdController.text;
    if (currentText.isNotEmpty) {
      _devoteeIdController.text = currentText.substring(0, currentText.length - 1);
    }
  }
  
  void _clearAll() {
    _devoteeIdController.text = '';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Devotee Check-in'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.indigo,
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
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('connectedDeviceAddress');
                  await prefs.remove('connectedDeviceName');
                  
                  setState(() {
                    _isPrinterConnected = false;
                  });
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Printer disconnected')),
                  );
                },
              ),
          ],
        ),
      ),
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
                        color: Colors.indigo,
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
                    Form(
                      key: _formKey,
                      child: TextFormField(
                        controller: _devoteeIdController,
                        decoration: InputDecoration(
                          labelText: 'Devotee ID',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your Devotee ID';
                          }
                          return null;
                        },
                        readOnly: true, // Use keypad instead of keyboard
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Custom Keypad
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildKeypadButton('1'),
                              _buildKeypadButton('2'),
                              _buildKeypadButton('3'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildKeypadButton('4'),
                              _buildKeypadButton('5'),
                              _buildKeypadButton('6'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildKeypadButton('7'),
                              _buildKeypadButton('8'),
                              _buildKeypadButton('9'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildKeypadButton('C', isFunction: true),
                              _buildKeypadButton('0'),
                              _buildKeypadButton('⌫', isFunction: true),
                            ],
                          ),
                        ],
                      ),
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
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Icon(
                        Icons.card_giftcard,
                        size: 64,
                        color: Colors.indigo,
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
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.print),
                          label: const Text('Print Label', style: TextStyle(fontSize: 18)),
                          onPressed: _printLabel,
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
  
  Widget _buildKeypadButton(String text, {bool isFunction = false}) {
    return SizedBox(
      width: 70,
      height: 70,
      child: ElevatedButton(
        onPressed: () {
          if (isFunction) {
            if (text == '⌫') {
              _clearDigit();
            } else if (text == 'C') {
              _clearAll();
            }
          } else {
            _addDigit(text);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isFunction ? Colors.grey[300] : null,
          foregroundColor: isFunction ? Colors.black : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(35),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _devoteeIdController.dispose();
    super.dispose();
  }
}

// Dashboard page for viewing reports and statistics
class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;
  Map<String, dynamic> _dailyData = {'labels': [], 'values': []};
  Map<String, dynamic> _monthlyData = {'labels': [], 'values': []};
  Map<String, dynamic> _yearlyData = {'labels': [], 'values': []};
  Map<String, dynamic> _devoteesData = {'labels': [], 'values': []};
  List<dynamic> _devotees = [];
  int _totalVisits = 0;
  int _dailyVisits = 0;
  int _monthlyVisits = 0;
  int _yearlyVisits = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load daily report
      var response = await http.get(Uri.parse('$baseUrl/api/reports/daily'));
      if (response.statusCode == 200) {
        _dailyData = json.decode(response.body);
      }

      // Load monthly report
      response = await http.get(Uri.parse('$baseUrl/api/reports/monthly'));
      if (response.statusCode == 200) {
        _monthlyData = json.decode(response.body);
      }

      // Load yearly report
      response = await http.get(Uri.parse('$baseUrl/api/reports/yearly'));
      if (response.statusCode == 200) {
        _yearlyData = json.decode(response.body);
      }

      // Load devotees report
      response = await http.get(Uri.parse('$baseUrl/api/reports/devotees'));
      if (response.statusCode == 200) {
        _devoteesData = json.decode(response.body);
      }

      // Load dashboard page (to get summary statistics)
      response = await http.get(Uri.parse('$baseUrl/dashboard'));
      if (response.statusCode == 200) {
        // Extract data from HTML (this is a simplified example)
        final html = response.body;
        
        // Extract total visits
        final totalMatch = RegExp(r'<div class="stat-value">(\d+)</div>\s*<div class="stat-label">Total Visits</div>')
            .firstMatch(html);
        if (totalMatch != null) {
          _totalVisits = int.parse(totalMatch.group(1)!);
        }
        
        // Extract daily visits
        final dailyMatch = RegExp(r'<div class="stat-value">(\d+)</div>\s*<div class="stat-label">Today\'s Visits</div>')
            .firstMatch(html);
        if (dailyMatch != null) {
          _dailyVisits = int.parse(dailyMatch.group(1)!);
        }
        
        // Extract monthly visits
        final monthlyMatch = RegExp(r'<div class="stat-value">(\d+)</div>\s*<div class="stat-label">This Month</div>')
            .firstMatch(html);
        if (monthlyMatch != null) {
          _monthlyVisits = int.parse(monthlyMatch.group(1)!);
        }
        
        // Extract yearly visits
        final yearlyMatch = RegExp(r'<div class="stat-value">(\d+)</div>\s*<div class="stat-label">This Year</div>')
            .firstMatch(html);
        if (yearlyMatch != null) {
          _yearlyVisits = int.parse(yearlyMatch.group(1)!);
        }
        
        // Extract devotees
        // This is a very simplified example - in a real app, you would use JSON APIs
        final devoteesRegex = RegExp(r'<tr>\s*<td[^>]*>([^<]*)</td>\s*<td[^>]*>([^<]*)</td>');
        final matches = devoteesRegex.allMatches(html);
        _devotees = matches.map((match) => {
          'id': match.group(1),
          'name': match.group(2),
        }).toList();
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load dashboard data: $e')),
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
        title: const Text('Dashboard'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.indigo,
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
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home Page'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Devotee Page'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/devotee');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Add Devotee'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/add-devotee');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', false);
                
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/home');
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out')),
                );
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dashboard',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(height: 24),
                          GridView.count(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            children: [
                              _buildStatCard('Total Visits', _totalVisits, Icons.people, Colors.indigo),
                              _buildStatCard('Today\'s Visits', _dailyVisits, Icons.today, Colors.green),
                              _buildStatCard('This Month', _monthlyVisits, Icons.calendar_month, Colors.orange),
                              _buildStatCard('This Year', _yearlyVisits, Icons.calendar_today, Colors.purple),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Daily Visits',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  height: 200,
                                  child: _buildDailyChart(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Monthly Visits',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  height: 200,
                                  child: _buildMonthlyChart(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Yearly Visits',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  height: 200,
                                  child: _buildYearlyChart(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Top Devotees',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  height: 200,
                                  child: _buildDevoteesChart(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Devotee List',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _devotees.isEmpty
                              ? Center(child: Text('No devotees found'))
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: _devotees.length,
                                  itemBuilder: (context, index) {
                                    final devotee = _devotees[index];
                                    return ListTile(
                                      title: Text(devotee['name']),
                                      subtitle: Text('ID: ${devotee['id']}'),
                                      trailing: IconButton(
                                        icon: Icon(Icons.info),
                                        onPressed: () => _showDevoteeDetails(devotee),
                                      ),
                                    );
                                  },
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
  
  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 16),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDailyChart() {
    if (_dailyData['labels'].isEmpty) {
      return Center(child: Text('No data available'));
    }

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < _dailyData['labels'].length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: _dailyData['values'][i].toDouble(),
              color: Colors.indigo,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (_dailyData['values'] as List).isEmpty
            ? 10
            : ((_dailyData['values'] as List).reduce((a, b) => a > b ? a : b) + 5).toDouble(),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: SideTitles(
            showTitles: true,
            getTitles: (value) {
              if (value.toInt() >= 0 && value.toInt() < _dailyData['labels'].length) {
                return _dailyData['labels'][value.toInt()];
              }
              return '';
            },
            margin: 10,
          ),
          leftTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
          ),
          topTitles: SideTitles(showTitles: false),
          rightTitles: SideTitles(showTitles: false),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }
  
  Widget _buildMonthlyChart() {
    if (_monthlyData['labels'].isEmpty) {
      return Center(child: Text('No data available'));
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < _monthlyData['labels'].length; i++) {
      spots.add(FlSpot(i.toDouble(), _monthlyData['values'][i].toDouble()));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: SideTitles(
            showTitles: true,
            getTitles: (value) {
              if (value.toInt() >= 0 && value.toInt() < _monthlyData['labels'].length) {
                return _monthlyData['labels'][value.toInt()];
              }
              return '';
            },
            margin: 10,
            reservedSize: 30,
          ),
          leftTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
          ),
          topTitles: SideTitles(showTitles: false),
          rightTitles: SideTitles(showTitles: false),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            colors: [Colors.blue],
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              colors: [Colors.blue.withOpacity(0.3)],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildYearlyChart() {
    if (_yearlyData['labels'].isEmpty) {
      return Center(child: Text('No data available'));
    }

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < _yearlyData['labels'].length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: _yearlyData['values'][i].toDouble(),
              color: Colors.orange,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (_yearlyData['values'] as List).isEmpty
            ? 10
            : ((_yearlyData['values'] as List).reduce((a, b) => a > b ? a : b) + 5).toDouble(),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: SideTitles(
            showTitles: true,
            getTitles: (value) {
              if (value.toInt() >= 0 && value.toInt() < _yearlyData['labels'].length) {
                return _yearlyData['labels'][value.toInt()];
              }
              return '';
            },
            margin: 10,
          ),
          leftTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
          ),
          topTitles: SideTitles(showTitles: false),
          rightTitles: SideTitles(showTitles: false),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }
  
  Widget _buildDevoteesChart() {
    if (_devoteesData['labels'].isEmpty) {
      return Center(child: Text('No data available'));
    }

    return PieChart(
      PieChartData(
        sections: List.generate(_devoteesData['labels'].length, (i) {
          final value = _devoteesData['values'][i].toDouble();
          final label = _devoteesData['labels'][i];
          
          // Generate a different color for each section
          final Color color = Colors.primaries[i % Colors.primaries.length];
          
          return PieChartSectionData(
            color: color,
            value: value,
            title: label,
            radius: 50,
            titleStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }
  
  void _showDevoteeDetails(Map<String, dynamic> devotee) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/devotee/${devotee['id']}/visits'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Show devotee details in a dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(data['devotee']['name']),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Devotee ID: ${data['devotee']['id']}'),
                Text('Total Visits: ${data['visits'].length}'),
                const SizedBox(height: 16),
                Text('Visit History:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  width: double.maxFinite,
                  child: data['visits'].isEmpty
                      ? Center(child: Text('No visits recorded'))
                      : ListView.builder(
                          itemCount: data['visits'].length,
                          itemBuilder: (context, index) {
                            final visit = data['visits'][index];
                            return ListTile(
                              title: Text(visit['item']),
                              subtitle: Text('Date: ${visit['date']}'),
                              leading: Icon(Icons.calendar_today),
                              dense: true,
                            );
                          },
                        ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load devotee details')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

// Add devotee page for registering new devotees
class AddDevoteePage extends StatefulWidget {
  const AddDevoteePage({Key? key}) : super(key: key);

  @override
  _AddDevoteePageState createState() => _AddDevoteePageState();
}

class _AddDevoteePageState extends State<AddDevoteePage> {
  final _formKey = GlobalKey<FormState>();
  final _devoteeIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  
  Future<void> _addDevotee() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/add_devotee'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'devotee_id': _devoteeIdController.text,
            'name': _nameController.text,
            'phone': _phoneController.text,
            'email': _emailController.text,
            'address': _addressController.text,
          },
        );
        
        if (response.statusCode == 200) {
          // Check if the devotee was added successfully
          if (response.body.contains('Devotee added successfully')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Devotee added successfully')),
            );
            
            // Clear the form
            _devoteeIdController.clear();
            _nameController.clear();
            _phoneController.clear();
            _emailController.clear();
            _addressController.clear();
          } else if (response.body.contains('Devotee ID already exists')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Devotee ID already exists')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to add devotee')),
            );
          }
        } else {
          // Handle error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add devotee: ${response.statusCode}')),
          );
        }
      } catch (e) {
        // Handle connection error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Devotee'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.indigo,
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
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home Page'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Devotee Page'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/devotee');
              },
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', false);
                
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/home');
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out')),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add New Devotee',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _devoteeIdController,
                            decoration: InputDecoration(
                              labelText: 'Devotee ID',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.badge),
                              helperText: 'A unique ID for the devotee (e.g., DEV001)',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a Devotee ID';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the devotee\'s name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              labelText: 'Address',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.home),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _addDevotee,
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    )
                                  : const Text('Add Devotee', style: TextStyle(fontSize: 18)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Use this form to register new devotees in the system.'),
                    const SizedBox(height: 8),
                    Text('The Devotee ID should be unique and will be used for check-ins.'),
                    const SizedBox(height: 8),
                    Text('All fields marked with * are required.'),
                    const Divider(height: 32),
                    Text('After adding a devotee, they will be able to use their ID to check in and receive a random item selection.'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Make sure to provide the devotee with their ID after registration.'),
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
    _devoteeIdController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
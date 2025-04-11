import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/devotee_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const TempleApp());
}

class TempleApp extends StatefulWidget {
  const TempleApp({Key? key}) : super(key: key);

  @override
  _TempleAppState createState() => _TempleAppState();
}

class _TempleAppState extends State<TempleApp> {
  bool _isLoggedIn = false;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }
  
  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Temple Management',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurple,
          elevation: 2,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        cardTheme: CardTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        textTheme: TextTheme(
          headline6: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple[800],
          ),
          bodyText1: TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
          bodyText2: TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurple[700],
          elevation: 2,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        cardTheme: CardTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          color: Colors.grey[850],
        ),
        textTheme: TextTheme(
          headline6: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple[100],
          ),
          bodyText1: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
          bodyText2: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
      ),
      themeMode: ThemeMode.system, // Follow system theme
      debugShowCheckedModeBanner: false,
      home: _isLoading
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : (_isLoggedIn ? const DevoteeScreen() : const LoginScreen()),
      routes: {
        '/home': (context) => const DevoteeScreen(),
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}
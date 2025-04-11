import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isAppActivated = true;
  
  final _apiService = ApiService();
  
  @override
  void initState() {
    super.initState();
    _checkAppActivation();
  }
  
  Future<void> _checkAppActivation() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final isActivated = await _apiService.isAppActivated();
      
      setState(() {
        _isAppActivated = isActivated;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking app activation: $e')),
      );
    }
  }
  
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _apiService.login(
        _usernameController.text,
        _passwordController.text,
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid username or password')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login error: $e')),
      );
    }
  }
  
  Future<void> _setupAdmin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _apiService.setupAdmin(
        _usernameController.text,
        'admin@example.com', // Default email
        _passwordController.text,
      );
      
      setState(() {
        _isLoading = false;
        _isAppActivated = success;
      });
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin account created successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create admin account')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Admin setup error: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        const Icon(
                          Icons.temple_hindu,
                          size: 80,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Temple Management',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isAppActivated
                              ? 'Please log in to continue'
                              : 'First time setup',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  Text(
                                    _isAppActivated
                                        ? 'Login'
                                        : 'Create Admin Account',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  TextFormField(
                                    controller: _usernameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Username',
                                      prefixIcon: Icon(Icons.person),
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a username';
                                      }
                                      if (!_isAppActivated && value.length < 4) {
                                        return 'Username must be at least 4 characters long';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _passwordController,
                                    decoration: const InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: Icon(Icons.lock),
                                      border: OutlineInputBorder(),
                                    ),
                                    obscureText: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a password';
                                      }
                                      if (!_isAppActivated && value.length < 6) {
                                        return 'Password must be at least 6 characters long';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _isAppActivated ? _login : _setupAdmin,
                                      child: Text(
                                        _isAppActivated
                                            ? 'Login'
                                            : 'Create Admin Account',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_isAppActivated)
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                            child: const Text(
                              'Continue without login',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
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
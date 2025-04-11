import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/devotee.dart';
import '../models/visit.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000'; // For Android emulator
  // Use 'http://localhost:5000' for iOS simulator
  // Use actual IP address/domain when deployed

  // User authentication
  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': username,
          'password': password,
        },
      );
      
      if (response.statusCode == 200) {
        // Check if login was successful by checking redirection
        final redirectUrl = response.request?.url.path;
        if (redirectUrl == '/' || redirectUrl == '/index' || redirectUrl == '/home') {
          // Save login status
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<bool> setupAdmin(String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin_setup'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': username,
          'email': email,
          'password': password,
          'confirm_password': password,
        },
      );
      
      if (response.statusCode == 200) {
        // Check if redirected to login page
        final redirectUrl = response.request?.url.path;
        return redirectUrl == '/login';
      }
      return false;
    } catch (e) {
      print('Admin setup error: $e');
      return false;
    }
  }

  Future<bool> logout() async {
    try {
      await http.get(Uri.parse('$baseUrl/logout'));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      return true;
    } catch (e) {
      print('Logout error: $e');
      return false;
    }
  }

  // Check if app is activated (has admin account)
  Future<bool> isAppActivated() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/'));
      final redirectUrl = response.request?.url.path;
      return redirectUrl != '/admin_setup';
    } catch (e) {
      print('Check activation error: $e');
      return false;
    }
  }

  // Devotee operations
  Future<Map<String, dynamic>?> checkInDevotee(String devoteeId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/devotee'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'devotee_id': devoteeId,
        },
      );
      
      if (response.statusCode == 200) {
        // Parse HTML to extract JSON data (since Flask returns HTML)
        final html = response.body;
        final printDataMatch = RegExp(r'data-print-data="([^"]*)"').firstMatch(html);
        
        if (printDataMatch != null && printDataMatch.groupCount >= 1) {
          final encodedData = printDataMatch.group(1)!;
          // Decode HTML entities
          final decodedData = htmlDecode(encodedData);
          // Parse JSON data
          return json.decode(decodedData);
        }
      }
      return null;
    } catch (e) {
      print('Check-in error: $e');
      return null;
    }
  }

  Future<bool> addDevotee(Devotee devotee) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add_devotee'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'devotee_id': devotee.id,
          'name': devotee.name,
          'phone': devotee.phone ?? '',
          'email': devotee.email ?? '',
          'address': devotee.address ?? '',
        },
      );
      
      return response.statusCode == 200 && 
             response.body.contains('Devotee added successfully');
    } catch (e) {
      print('Add devotee error: $e');
      return false;
    }
  }

  // Reports
  Future<Map<String, dynamic>> getDailyReport() async {
    return _getReport('daily');
  }

  Future<Map<String, dynamic>> getMonthlyReport() async {
    return _getReport('monthly');
  }

  Future<Map<String, dynamic>> getYearlyReport() async {
    return _getReport('yearly');
  }

  Future<Map<String, dynamic>> getDevoteesReport() async {
    return _getReport('devotees');
  }

  Future<Map<String, dynamic>> _getReport(String reportType) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/reports/$reportType'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'labels': [], 'values': []};
    } catch (e) {
      print('Get report error: $e');
      return {'labels': [], 'values': []};
    }
  }

  // Get devotee visits
  Future<Map<String, dynamic>?> getDevoteeVisits(String devoteeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/devotee/$devoteeId/visits'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Get devotee visits error: $e');
      return null;
    }
  }

  // Stats for dashboard
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/dashboard'));
      
      if (response.statusCode == 200) {
        final html = response.body;
        
        // Extract statistics from HTML
        final Map<String, dynamic> stats = {};
        
        // Extract total visits
        final totalMatch = RegExp(r'<div class="stat-value">(\d+)</div>\s*<div class="stat-label">Total Visits</div>')
            .firstMatch(html);
        if (totalMatch != null) {
          stats['totalVisits'] = int.parse(totalMatch.group(1)!);
        }
        
        // Extract daily visits
        final dailyMatch = RegExp(r'<div class="stat-value">(\d+)</div>\s*<div class="stat-label">Today\'s Visits</div>')
            .firstMatch(html);
        if (dailyMatch != null) {
          stats['dailyVisits'] = int.parse(dailyMatch.group(1)!);
        }
        
        // Extract monthly visits
        final monthlyMatch = RegExp(r'<div class="stat-value">(\d+)</div>\s*<div class="stat-label">This Month</div>')
            .firstMatch(html);
        if (monthlyMatch != null) {
          stats['monthlyVisits'] = int.parse(monthlyMatch.group(1)!);
        }
        
        // Extract yearly visits
        final yearlyMatch = RegExp(r'<div class="stat-value">(\d+)</div>\s*<div class="stat-label">This Year</div>')
            .firstMatch(html);
        if (yearlyMatch != null) {
          stats['yearlyVisits'] = int.parse(yearlyMatch.group(1)!);
        }
        
        // Extract total devotees
        final devoteesMatch = RegExp(r'<div class="stat-value">(\d+)</div>\s*<div class="stat-label">Total Devotees</div>')
            .firstMatch(html);
        if (devoteesMatch != null) {
          stats['totalDevotees'] = int.parse(devoteesMatch.group(1)!);
        }
        
        return stats;
      }
      return {};
    } catch (e) {
      print('Get dashboard stats error: $e');
      return {};
    }
  }

  // Helper method to decode HTML entities
  String htmlDecode(String input) {
    return input
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&#39;', "'");
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  // Use 10.0.2.2 for Android emulator to connect to localhost on the host machine
  static const String baseUrl = 'http://10.0.2.2:5000/api/v1/auth';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _storage.write(key: 'auth_token', value: data['access_token']);
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  Future<Map<String, dynamic>?> register(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'full_name': fullName,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Registration failed');
      }
    } catch (e) {
      print(
        'An error occurred during registration: $e',
      ); // Print the error to the debug console
      throw Exception('Registration error: $e');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    await _storage.deleteAll(); // Clear all stored data
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  /// Validates if the JWT token has correct format (3 segments)
  bool isValidTokenFormat(String? token) {
    if (token == null || token.isEmpty) return false;
    final segments = token.split('.');
    return segments.length == 3;
  }

  /// Checks if user has a valid token stored
  Future<bool> hasValidToken() async {
    final token = await getToken();
    return isValidTokenFormat(token);
  }

  Future<void> deleteAccount() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Not authenticated');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/account'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await logout();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to delete account');
      }
    } catch (e) {
      throw Exception('Delete account error: $e');
    }
  }
}

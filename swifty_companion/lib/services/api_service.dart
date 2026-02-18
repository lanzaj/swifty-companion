import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import '../models.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _storage = const FlutterSecureStorage();

  // Backend URL - machine's IP if running on physical device
  // Android Emulator uses 10.0.2.2 to access host localhost
  String get _backendUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  Future<String?> get _accessToken async =>
      await _storage.read(key: 'access_token');
  Future<String?> get _refreshToken async =>
      await _storage.read(key: 'refresh_token');

  Future<User?> fetchUser(String login) async {
    final token = await _accessToken;
    if (token == null) return null;

    var url = Uri.parse('https://api.intra.42.fr/v2/users/$login');
    var response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 401) {
      debugPrint("Token expired, attempting refresh...");
      bool refreshed = await _performTokenRefresh();
      if (refreshed) {
        String? newToken = await _accessToken;
        response = await http.get(
          url,
          headers: {'Authorization': 'Bearer $newToken'},
        );
      }
    }

    if (response.statusCode == 200) {
      // debugPrint("USER JSON DATA:");
      // // Print in chunks to avoid truncation
      // const int chunkSize = 800;
      // final String text = response.body;
      // for (int i = 0; i < text.length; i += chunkSize) {
      //   int end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
      //   debugPrint(text.substring(i, end));
      // }
      return User.fromJson(jsonDecode(response.body));
    } else {
      debugPrint('Failed to fetch user: ${response.statusCode}');
      return null;
    }
  }

  Future<bool> _performTokenRefresh() async {
    String? rToken = await _refreshToken;
    if (rToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': rToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'access_token', value: data['access_token']);
        if (data['refresh_token'] != null) {
          await _storage.write(
            key: 'refresh_token',
            value: data['refresh_token'],
          );
        }
        debugPrint("Token refreshed successfully.");
        return true;
      } else {
        debugPrint("Failed to refresh token: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Error refreshing token: $e");
      return false;
    }
  }
}

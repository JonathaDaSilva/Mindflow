import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  // Emulador Android usa 10.0.2.2 para acessar localhost do host
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await _getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<http.Response> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> get(String path) async {
    return http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );
  }

  static Future<http.Response> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    return http.put(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    return http.patch(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> delete(String path) async {
    return http.delete(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );
  }
}
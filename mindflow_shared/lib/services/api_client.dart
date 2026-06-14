import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  // Web (Chrome) usa localhost; emulador Android usa 10.0.2.2
  static String get baseUrl =>
      kIsWeb ? 'http://localhost:8080/api' : 'http://10.0.2.2:8080/api';

  static const Duration _timeout = Duration(seconds: 15);

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  static Future<http.Response> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    return http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
  }

  static Future<http.Response> get(String path) async {
    return http
        .get(Uri.parse('$baseUrl$path'), headers: await _headers())
        .timeout(_timeout);
  }

  static Future<http.Response> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    return http
        .put(
          Uri.parse('$baseUrl$path'),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
  }

  static Future<http.Response> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    return http
        .patch(
          Uri.parse('$baseUrl$path'),
          headers: await _headers(),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
  }

  static Future<http.Response> delete(String path) async {
    return http
        .delete(Uri.parse('$baseUrl$path'), headers: await _headers())
        .timeout(_timeout);
  }

  // ── SSE — Server-Sent Events ──────────────────────────────────────────────
  // Usado pelo ConsultaMonitorService para receber notificações em tempo real.
  static Future<Stream<String>> sseStream(String path) async {
    final headers = await _headers();
    headers['Accept'] = 'text/event-stream';
    headers['Cache-Control'] = 'no-cache';

    final request = http.Request('GET', Uri.parse('$baseUrl$path'));
    request.headers.addAll(headers);

    final client = http.Client();
    final response = await client.send(request);

    if (response.statusCode != 200) {
      client.close();
      throw Exception('SSE falhou: HTTP ${response.statusCode}');
    }

    final controller = StreamController<String>();

    final sub = response.stream
        .transform(const Utf8Decoder())
        .transform(const LineSplitter())
        .listen(
          (linha) => controller.add(linha),
          onError: (e) {
            controller.addError(e);
            controller.close();
            client.close();
          },
          onDone: () {
            controller.close();
            client.close();
          },
        );

    controller.onCancel = () {
      sub.cancel();
      client.close();
    };

    return controller.stream;
  }
}
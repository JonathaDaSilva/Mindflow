import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  // Em emulador Android → 10.0.2.2 = localhost da máquina
  // Em dispositivo físico → troque pelo IP da sua máquina na rede Wi-Fi
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  // ── Token ─────────────────────────────────────────────────────────────────

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ── Headers padrão ────────────────────────────────────────────────────────

  static Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  // ── REST ──────────────────────────────────────────────────────────────────

  static Future<http.Response> get(String path) async {
    return http.get(Uri.parse('$baseUrl$path'), headers: await _headers());
  }

  static Future<http.Response> post(
      String path, Map<String, dynamic> body) async {
    return http.post(Uri.parse('$baseUrl$path'),
        headers: await _headers(), body: jsonEncode(body));
  }

  static Future<http.Response> put(
      String path, Map<String, dynamic> body) async {
    return http.put(Uri.parse('$baseUrl$path'),
        headers: await _headers(), body: jsonEncode(body));
  }

  static Future<http.Response> patch(
      String path, Map<String, dynamic> body) async {
    return http.patch(Uri.parse('$baseUrl$path'),
        headers: await _headers(), body: jsonEncode(body));
  }

  static Future<http.Response> delete(String path) async {
    return http.delete(Uri.parse('$baseUrl$path'), headers: await _headers());
  }

  // ── SSE — Server-Sent Events ──────────────────────────────────────────────
  //
  // O backend Spring publica neste stream sempre que o consumer RabbitMQ
  // processa um evento. O Flutter recebe as linhas em tempo real sem
  // precisar de WebSocket ou biblioteca extra.
  //
  // Uso:
  //   final stream = await ApiClient.sseStream('/notificacoes/stream');
  //   stream.listen((linha) { ... });
  //
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
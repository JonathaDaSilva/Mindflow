import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_response.dart';
import 'api_client.dart';

class AuthService {
  static Future<AuthResponse> login(String email, String senha) async {
    final res = await ApiClient.post(
      '/auth/login',
      {'email': email, 'senha': senha},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final auth = AuthResponse.fromJson(data);
      await _salvarSessao(auth);
      return auth;
    }

    final erro = jsonDecode(res.body)['error'] ?? 'Erro ao fazer login';
    throw Exception(erro);
  }

  static Future<AuthResponse> registrar(Map<String, dynamic> body) async {
    final res = await ApiClient.post('/auth/registrar', body);

    if (res.statusCode == 201) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final auth = AuthResponse.fromJson(data);
      await _salvarSessao(auth);
      return auth;
    }

    final erro = jsonDecode(res.body)['error'] ?? 'Erro ao registrar';
    throw Exception(erro);
  }

  static Future<void> _salvarSessao(AuthResponse auth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token',  auth.token);
    await prefs.setString('userId', auth.userId);
    await prefs.setString('nome',   auth.nome);
    await prefs.setString('email',  auth.email);
    await prefs.setString('perfil', auth.perfil);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<bool> isLogado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }

  static Future<String?> getNome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nome');
  }

  static Future<String?> getPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('perfil');
  }
}
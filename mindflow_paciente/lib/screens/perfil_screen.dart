import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mindflow_shared/mindflow_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String _nome   = '';
  String _email  = '';
  bool   _loading = true;
  String? _erro;

  // Campos editáveis
  final _nomeCtrl = TextEditingController();
  bool _editando  = false;
  bool _salvando  = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final res = await ApiClient.get('/usuarios/me');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _nome  = data['nome']  as String;
          _email = data['email'] as String;
          _nomeCtrl.text = _nome;
        });
        // Atualiza SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('nome', _nome);
      }
    } catch (e) {
      setState(() => _erro = 'Erro ao carregar perfil');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _salvarNome() async {
    if (_nomeCtrl.text.trim().isEmpty) return;
    setState(() => _salvando = true);
    try {
      final res = await ApiClient.put(
        '/usuarios/me',
        {'nome': _nomeCtrl.text.trim()},
      );
      if (res.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('nome', _nomeCtrl.text.trim());
        setState(() {
          _nome     = _nomeCtrl.text.trim();
          _editando = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nome atualizado!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      setState(() => _erro = 'Erro ao salvar');
    } finally {
      setState(() => _salvando = false);
    }
  }

  Future<void> _logout() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Sair',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Deseja sair da sua conta?',
            style: TextStyle(color: AppTheme.textSecond)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppTheme.textSecond)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Meu Perfil',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded,
                color: AppTheme.error),
            onPressed: _logout,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Avatar grande
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _nome.isNotEmpty
                              ? _nome[0].toUpperCase() : '?',
                          style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(_nome,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 4),
                    Text(_email,
                        style: const TextStyle(
                            color: AppTheme.textSecond, fontSize: 14)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('PACIENTE',
                          style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),

                    const SizedBox(height: 36),

                    // Card editar nome
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Dados pessoais',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary)),
                              GestureDetector(
                                onTap: () => setState(
                                    () => _editando = !_editando),
                                child: Text(
                                  _editando ? 'Cancelar' : 'Editar',
                                  style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_editando) ...[
                            TextFormField(
                              controller: _nomeCtrl,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary),
                              decoration: const InputDecoration(
                                labelText: 'Nome',
                                prefixIcon: Icon(Icons.person_outline,
                                    color: AppTheme.textSecond),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _salvando ? null : _salvarNome,
                              child: _salvando
                                  ? const SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : const Text('Salvar alterações'),
                            ),
                          ] else ...[
                            _infoRow(Icons.person_outline, 'Nome', _nome),
                            const SizedBox(height: 12),
                            _infoRow(Icons.email_outlined, 'E-mail',
                                _email),
                          ],
                        ],
                      ),
                    ),

                    if (_erro != null) ...[
                      const SizedBox(height: 12),
                      Text(_erro!,
                          style: const TextStyle(color: AppTheme.error)),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _infoRow(IconData icon, String label, String valor) {
    return Row(children: [
      Icon(icon, color: AppTheme.textSecond, size: 18),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecond, fontSize: 11)),
        Text(valor,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500)),
      ]),
    ]);
  }
}
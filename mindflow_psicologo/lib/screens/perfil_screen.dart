import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mindflow_shared/mindflow_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/psicologo_theme.dart';
import 'login_screen.dart';
import 'disponibilidade_screen.dart';

class PerfilScreen extends StatefulWidget {
  final bool isTab;
  final VoidCallback? onNomeAtualizado;

  const PerfilScreen({
    super.key,
    this.isTab = false,
    this.onNomeAtualizado,
  });

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String _nome  = '';
  String _email = '';
  bool   _loading  = true;
  bool   _editando = false;
  bool   _salvando = false;
  String? _erro;

  final _nomeCtrl = TextEditingController();

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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('nome', _nome);
      }
    } catch (_) {
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
          '/usuarios/me', {'nome': _nomeCtrl.text.trim()});
      if (res.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('nome', _nomeCtrl.text.trim());
        setState(() {
          _nome    = _nomeCtrl.text.trim();
          _editando = false;
        });
        widget.onNomeAtualizado?.call();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Nome atualizado!'),
          backgroundColor: PT.success,
        ));
      }
    } catch (_) {
      setState(() => _erro = 'Erro ao salvar');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _logout() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Deseja encerrar a sessão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: PT.error),
            child: const Text('Sair'),
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
      backgroundColor: PT.background,
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        leading: widget.isTab
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pop(context),
              ),
        automaticallyImplyLeading: !widget.isTab,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
            color: PT.error,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: PT.primary))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Card de perfil
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: PT.card,
                      child: Column(
                        children: [
                          // Avatar grande
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: PT.primaryLight,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: PT.primary.withOpacity(0.2),
                                  width: 2),
                            ),
                            child: Center(
                              child: Text(
                                _nome.isNotEmpty
                                    ? _nome[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                    color: PT.primary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(_nome,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: PT.text1)),
                          const SizedBox(height: 4),
                          Text(_email,
                              style: const TextStyle(
                                  color: PT.text2, fontSize: 13)),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: PT.primaryLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Psicólogo',
                              style: TextStyle(
                                  color: PT.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Card dados pessoais
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: PT.card,
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
                                      color: PT.text1,
                                      fontSize: 15)),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _editando = !_editando),
                                child: Text(_editando ? 'Cancelar' : 'Editar'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_editando) ...[
                            TextFormField(
                              controller: _nomeCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nome',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: _salvando ? null : _salvarNome,
                              child: _salvando
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : const Text('Salvar alterações'),
                            ),
                          ] else ...[
                            PT.infoRow(
                                Icons.person_outline, 'Nome', _nome),
                            const SizedBox(height: 14),
                            const Divider(height: 1),
                            const SizedBox(height: 14),
                            PT.infoRow(Icons.email_outlined, 'E-mail',
                                _email),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Atalho para disponibilidade
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const DisponibilidadeScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: PT.card,
                        child: Row(children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.tune_rounded,
                                color: PT.success, size: 20),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('Minha disponibilidade',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: PT.text1,
                                        fontSize: 14)),
                                SizedBox(height: 2),
                                Text('Gerenciar horários de atendimento',
                                    style: TextStyle(
                                        color: PT.text2, fontSize: 12)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: PT.text3),
                        ]),
                      ),
                    ),

                    if (_erro != null) ...[
                      const SizedBox(height: 12),
                      Text(_erro!,
                          style: const TextStyle(color: PT.error)),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

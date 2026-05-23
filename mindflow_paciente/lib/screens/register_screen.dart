import 'package:flutter/material.dart';
import 'package:mindflow_shared/services/auth_service.dart';
import 'package:mindflow_shared/theme/app_theme.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nomeCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _telCtrl   = TextEditingController();

  bool _loading  = false;
  bool _senhaVis = false;
  String? _erro;

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _erro = null; });

    try {
      await AuthService.registrar({
        'nome':   _nomeCtrl.text.trim(),
        'email':  _emailCtrl.text.trim(),
        'senha':  _senhaCtrl.text,
        'perfil': 'PACIENTE',
        'dadosPaciente': {
          'telefone': _telCtrl.text.trim(),
        },
      });
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (e) {
      setState(() => _erro = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _telCtrl.dispose();
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Criar conta',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 8),
                const Text('Preencha seus dados para começar',
                    style: TextStyle(color: AppTheme.textSecond)),
                const SizedBox(height: 36),

                _field(_nomeCtrl, 'Nome completo',
                    Icons.person_outline, false,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nome obrigatório' : null),
                const SizedBox(height: 14),

                _field(_emailCtrl, 'E-mail',
                    Icons.email_outlined, false,
                    tipo: TextInputType.emailAddress,
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'E-mail inválido' : null),
                const SizedBox(height: 14),

                _field(_telCtrl, 'Telefone',
                    Icons.phone_outlined, false,
                    tipo: TextInputType.phone),
                const SizedBox(height: 14),

                // Senha com toggle
                TextFormField(
                  controller: _senhaCtrl,
                  obscureText: !_senhaVis,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppTheme.textSecond),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _senhaVis
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppTheme.textSecond,
                      ),
                      onPressed: () =>
                          setState(() => _senhaVis = !_senhaVis),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 12),

                if (_erro != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline,
                          color: AppTheme.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_erro!,
                            style: const TextStyle(
                                color: AppTheme.error, fontSize: 13)),
                      ),
                    ]),
                  ),

                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: _loading ? null : _registrar,
                  child: _loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Criar conta'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon,
    bool obscure, {
    TextInputType tipo = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: tipo,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textSecond),
      ),
      validator: validator,
    );
  }
}
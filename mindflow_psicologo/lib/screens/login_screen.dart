import 'package:flutter/material.dart';
import 'package:mindflow_shared/mindflow_shared.dart';
import '../theme/psicologo_theme.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();

  bool    _loading  = false;
  bool    _senhaVis = false;
  String? _erro;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _erro = null; });

    try {
      final auth = await AuthService.login(
          _emailCtrl.text.trim(), _senhaCtrl.text);

      if (auth.perfil != 'PSICOLOGO') {
        throw Exception('Use o app do paciente para acessar com este perfil.');
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      setState(() => _erro = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PT.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // Logo
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: PT.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: PT.primary.withOpacity(0.15), width: 1),
                  ),
                  child: const Icon(Icons.psychology_rounded,
                      color: PT.primary, size: 30),
                ),
                const SizedBox(height: 28),

                const Text(
                  'Bem-vindo de volta',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: PT.text1,
                      letterSpacing: -0.3),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Acesse sua agenda e gerencie consultas',
                  style: TextStyle(color: PT.text2, fontSize: 14),
                ),

                const SizedBox(height: 36),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-mail profissional',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
                ),
                const SizedBox(height: 14),

                // Senha
                TextFormField(
                  controller: _senhaCtrl,
                  obscureText: !_senhaVis,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_senhaVis
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () =>
                          setState(() => _senhaVis = !_senhaVis),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Mínimo 6 caracteres'
                      : null,
                ),

                const SizedBox(height: 12),

                // Erro
                if (_erro != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PT.errorLight,
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: PT.error.withOpacity(0.3), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: PT.error, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_erro!,
                              style: const TextStyle(
                                  color: PT.error, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 8),

                // Botão entrar
                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Entrar'),
                ),

                const SizedBox(height: 24),

                // Criar conta
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Novo profissional? ',
                        style: TextStyle(color: PT.text2, fontSize: 14)),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen()),
                      ),
                      child: const Text(
                        'Criar conta',
                        style: TextStyle(
                            color: PT.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

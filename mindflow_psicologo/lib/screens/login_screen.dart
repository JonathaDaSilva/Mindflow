import 'package:flutter/material.dart';
import 'package:mindflow_shared/mindflow_shared.dart';
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

  bool _loading  = false;
  bool _senhaVis = false;
  String? _erro;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _erro = null; });

    try {
      final auth = await AuthService.login(
          _emailCtrl.text.trim(), _senhaCtrl.text);

      // Garante que é psicólogo
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.medical_services_rounded,
                      color: AppTheme.secondary, size: 32),
                ),
                const SizedBox(height: 32),
                const Text('Área do\nProfissional 🩺',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        height: 1.3)),
                const SizedBox(height: 8),
                const Text('Acesse sua agenda e gerencie consultas',
                    style: TextStyle(color: AppTheme.textSecond)),
                const SizedBox(height: 40),

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'E-mail profissional',
                    prefixIcon: Icon(Icons.email_outlined,
                        color: AppTheme.textSecond),
                  ),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'E-mail inválido' : null,
                ),
                const SizedBox(height: 16),

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
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Entrar'),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Novo profissional? ',
                        style: TextStyle(color: AppTheme.textSecond)),
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen())),
                      child: const Text('Criar conta',
                          style: TextStyle(
                              color: AppTheme.secondary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
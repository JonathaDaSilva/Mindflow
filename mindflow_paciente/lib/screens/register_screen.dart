import 'package:flutter/material.dart';
import 'package:mindflow_shared/mindflow_shared.dart';
import '../theme/paciente_theme.dart';
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
  bool    _loading  = false;
  bool    _senhaVis = false;
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
        'dadosPaciente': {'telefone': _telCtrl.text.trim()},
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
    _nomeCtrl.dispose(); _emailCtrl.dispose();
    _senhaCtrl.dispose(); _telCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PcT.background,
      appBar: AppBar(
        title: const Text('Criar conta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text('Preencha seus dados para começar',
                    style: TextStyle(color: PcT.text2, fontSize: 14)),
                const SizedBox(height: 28),

                _field(_nomeCtrl, 'Nome completo', Icons.person_outline,
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Nome obrigatório' : null),
                const SizedBox(height: 14),

                _field(_emailCtrl, 'E-mail', Icons.email_outlined,
                    tipo: TextInputType.emailAddress,
                    validator: (v) =>
                        !v!.contains('@') ? 'E-mail inválido' : null),
                const SizedBox(height: 14),

                _field(_telCtrl, 'Telefone', Icons.phone_outlined,
                    tipo: TextInputType.phone),
                const SizedBox(height: 14),

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
                      onPressed: () => setState(() => _senhaVis = !_senhaVis),
                    ),
                  ),
                  validator: (v) =>
                      v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                ),

                if (_erro != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PcT.errorLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: PcT.error.withOpacity(0.3), width: 1),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: PcT.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_erro!,
                          style: const TextStyle(color: PcT.error, fontSize: 13))),
                    ]),
                  ),
                ],

                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _loading ? null : _registrar,
                  child: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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

  Widget _field(TextEditingController ctrl, String label, IconData icon, {
    TextInputType tipo = TextInputType.text,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        keyboardType: tipo,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        validator: validator,
      );
}

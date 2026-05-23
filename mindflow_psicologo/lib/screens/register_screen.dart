import 'package:flutter/material.dart';
import 'package:mindflow_shared/mindflow_shared.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nomeCtrl   = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _senhaCtrl  = TextEditingController();
  final _crpCtrl    = TextEditingController();
  final _especCtrl  = TextEditingController();
  final _valorCtrl  = TextEditingController();

  bool _loading  = false;
  bool _senhaVis = false;
  bool _emergencia = false;
  String _regime = 'HIBRIDO';
  String? _erro;

  final List<Map<String, String>> _regimes = [
    {'value': 'PRESENCIAL', 'label': 'Presencial'},
    {'value': 'REMOTO',     'label': 'Remoto'},
    {'value': 'HIBRIDO',    'label': 'Híbrido'},
  ];

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _erro = null; });

    try {
      await AuthService.registrar({
        'nome':   _nomeCtrl.text.trim(),
        'email':  _emailCtrl.text.trim(),
        'senha':  _senhaCtrl.text,
        'perfil': 'PSICOLOGO',
        'dadosPsicologo': {
          'crp':            _crpCtrl.text.trim(),
          'especialidade':  _especCtrl.text.trim(),
          'regimeTrabalho': _regime,
          'duracaoSessaoMin': 50,
          'valorSessao': double.tryParse(_valorCtrl.text) ?? 0,
          'aceitaEmergencia': _emergencia,
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
    _nomeCtrl.dispose(); _emailCtrl.dispose();
    _senhaCtrl.dispose(); _crpCtrl.dispose();
    _especCtrl.dispose(); _valorCtrl.dispose();
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
        title: const Text('Cadastro profissional',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dados pessoais',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecond,
                        letterSpacing: 0.5)),
                const SizedBox(height: 14),

                _field(_nomeCtrl, 'Nome completo', Icons.person_outline,
                    validator: (v) => v!.trim().isEmpty
                        ? 'Nome obrigatório' : null),
                const SizedBox(height: 14),

                _field(_emailCtrl, 'E-mail', Icons.email_outlined,
                    tipo: TextInputType.emailAddress,
                    validator: (v) => !v!.contains('@')
                        ? 'E-mail inválido' : null),
                const SizedBox(height: 14),

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
                  validator: (v) => v!.length < 6
                      ? 'Mínimo 6 caracteres' : null,
                ),

                const SizedBox(height: 28),
                const Text('Dados profissionais',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecond,
                        letterSpacing: 0.5)),
                const SizedBox(height: 14),

                _field(_crpCtrl, 'CRP (ex: 06/12345)',
                    Icons.badge_outlined,
                    validator: (v) => v!.trim().isEmpty
                        ? 'CRP obrigatório' : null),
                const SizedBox(height: 14),

                _field(_especCtrl, 'Especialidade',
                    Icons.psychology_outlined),
                const SizedBox(height: 14),

                _field(_valorCtrl, 'Valor da sessão (R\$)',
                    Icons.attach_money_rounded,
                    tipo: TextInputType.number),
                const SizedBox(height: 14),

                // Regime
                DropdownButtonFormField<String>(
                  value: _regime,
                  dropdownColor: AppTheme.surfaceAlt,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Regime de trabalho',
                    prefixIcon: const Icon(Icons.work_outline,
                        color: AppTheme.textSecond),
                    filled: true,
                    fillColor: AppTheme.surfaceAlt,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: _regimes.map((r) => DropdownMenuItem(
                    value: r['value'],
                    child: Text(r['label']!),
                  )).toList(),
                  onChanged: (v) => setState(() => _regime = v!),
                ),
                const SizedBox(height: 8),

                // Emergências
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SwitchListTile(
                    title: const Text('Aceitar emergências',
                        style: TextStyle(
                            color: AppTheme.textPrimary, fontSize: 14)),
                    subtitle: const Text('Atendimentos urgentes remotos',
                        style: TextStyle(
                            color: AppTheme.textSecond, fontSize: 12)),
                    value: _emergencia,
                    activeColor: AppTheme.secondary,
                    onChanged: (v) => setState(() => _emergencia = v),
                  ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondary,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Criar conta profissional'),
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
    IconData icon, {
    TextInputType tipo = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
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
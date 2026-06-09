import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mindflow_shared/mindflow_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/paciente_theme.dart';
import 'login_screen.dart';

class PerfilScreen extends StatefulWidget {
  final bool isTab;
  final VoidCallback? onNomeAtualizado;

  const PerfilScreen({super.key, this.isTab = false, this.onNomeAtualizado});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String  _nome     = '';
  String  _email    = '';
  bool    _loading  = true;
  bool    _editando = false;
  bool    _salvando = false;
  String? _erro;

  final _nomeCtrl = TextEditingController();

  // Dados complementares (RF03 / RF13) — telefone, data de nascimento,
  // forma de pagamento preferida e observações de saúde, via /pacientes/perfil
  bool    _editandoComplemento = false;
  bool    _salvandoComplemento = false;
  DateTime? _dataNascimento;
  String?   _formaPagamentoPref;

  final _telefoneCtrl    = TextEditingController();
  final _observacoesCtrl = TextEditingController();

  static const Map<String, String> _formasPagamento = {
    'PIX':            'Pix',
    'CARTAO_CREDITO': 'Cartão de crédito',
    'CARTAO_DEBITO':  'Cartão de débito',
    'CONVENIO':       'Convênio',
    'DINHEIRO':       'Dinheiro',
  };

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
      await _carregarPerfilComplementar();
    } catch (_) {
      setState(() => _erro = 'Erro ao carregar perfil');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _carregarPerfilComplementar() async {
    try {
      final res = await ApiClient.get('/pacientes/perfil');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _telefoneCtrl.text = (data['telefone'] as String?) ?? '';
          _observacoesCtrl.text = (data['observacoesSaude'] as String?) ?? '';
          _formaPagamentoPref = data['formaPagamentoPref'] as String?;
          final nasc = data['dataNascimento'] as String?;
          _dataNascimento = (nasc == null || nasc.isEmpty)
              ? null
              : DateTime.tryParse(nasc);
        });
      }
    } catch (_) {
      // dados complementares são opcionais — falha silenciosa não impede o perfil básico
    }
  }

  Future<void> _selecionarDataNascimento() async {
    final agora = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataNascimento ?? DateTime(agora.year - 25),
      firstDate: DateTime(1900),
      lastDate: agora,
      helpText: 'Data de nascimento',
    );
    if (picked != null) setState(() => _dataNascimento = picked);
  }

  String _formatarData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _salvarComplemento() async {
    setState(() => _salvandoComplemento = true);
    try {
      final body = {
        'telefone': _telefoneCtrl.text.trim().isEmpty
            ? null : _telefoneCtrl.text.trim(),
        'dataNascimento': _dataNascimento == null
            ? null
            : '${_dataNascimento!.year.toString().padLeft(4, '0')}-'
              '${_dataNascimento!.month.toString().padLeft(2, '0')}-'
              '${_dataNascimento!.day.toString().padLeft(2, '0')}',
        'formaPagamentoPref': _formaPagamentoPref,
        'observacoesSaude': _observacoesCtrl.text.trim().isEmpty
            ? null : _observacoesCtrl.text.trim(),
      };
      final res = await ApiClient.put('/pacientes/perfil', body);
      if (res.statusCode == 200) {
        setState(() => _editandoComplemento = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Dados atualizados!'),
          backgroundColor: PcT.success,
        ));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ${res.statusCode} ao salvar dados'),
          backgroundColor: PcT.error,
        ));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Verifique sua conexão e tente novamente'),
        backgroundColor: PcT.error,
      ));
    } finally {
      if (mounted) setState(() => _salvandoComplemento = false);
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
        setState(() { _nome = _nomeCtrl.text.trim(); _editando = false; });
        widget.onNomeAtualizado?.call();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Nome atualizado!'),
          backgroundColor: PcT.success,
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
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: PcT.error),
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
    _telefoneCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PcT.background,
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
            color: PcT.error,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: PcT.primary))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Card de identidade
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: PcT.card,
                      child: Column(children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: PcT.primaryLight,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: PcT.primary.withOpacity(0.2), width: 2),
                          ),
                          child: Center(
                            child: Text(
                              _nome.isNotEmpty ? _nome[0].toUpperCase() : '?',
                              style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  color: PcT.primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(_nome,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: PcT.text1)),
                        const SizedBox(height: 4),
                        Text(_email,
                            style: const TextStyle(
                                color: PcT.text2, fontSize: 13)),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: PcT.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Paciente',
                              style: TextStyle(
                                  color: PcT.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 16),

                    // Card dados pessoais
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: PcT.card,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Dados pessoais',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: PcT.text1,
                                      fontSize: 15)),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _editando = !_editando),
                                child:
                                    Text(_editando ? 'Cancelar' : 'Editar'),
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
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : const Text('Salvar alterações'),
                            ),
                          ] else ...[
                            _infoRow(Icons.person_outline, 'Nome', _nome),
                            const SizedBox(height: 14),
                            const Divider(height: 1),
                            const SizedBox(height: 14),
                            _infoRow(Icons.email_outlined, 'E-mail', _email),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Card de dados complementares (RF03 / RF13)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: PcT.card,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Dados complementares',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: PcT.text1,
                                      fontSize: 15)),
                              TextButton(
                                onPressed: () => setState(
                                    () => _editandoComplemento = !_editandoComplemento),
                                child: Text(
                                    _editandoComplemento ? 'Cancelar' : 'Editar'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_editandoComplemento) ...[
                            TextFormField(
                              controller: _telefoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Telefone',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                            ),
                            const SizedBox(height: 14),
                            InkWell(
                              onTap: _selecionarDataNascimento,
                              borderRadius: BorderRadius.circular(8),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Data de nascimento',
                                  prefixIcon: Icon(Icons.cake_outlined),
                                ),
                                child: Text(
                                  _dataNascimento == null
                                      ? 'Toque para selecionar'
                                      : _formatarData(_dataNascimento!),
                                  style: TextStyle(
                                    color: _dataNascimento == null
                                        ? PcT.text2 : PcT.text1,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              value: _formaPagamentoPref,
                              decoration: const InputDecoration(
                                labelText: 'Forma de pagamento preferida',
                                prefixIcon: Icon(Icons.payments_outlined),
                              ),
                              items: _formasPagamento.entries
                                  .map((e) => DropdownMenuItem(
                                      value: e.key, child: Text(e.value)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _formaPagamentoPref = v),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _observacoesCtrl,
                              maxLines: 3,
                              maxLength: 1000,
                              decoration: const InputDecoration(
                                labelText: 'Observações de saúde',
                                alignLabelWithHint: true,
                                prefixIcon: Icon(Icons.health_and_safety_outlined),
                              ),
                            ),
                            const SizedBox(height: 4),
                            ElevatedButton(
                              onPressed:
                                  _salvandoComplemento ? null : _salvarComplemento,
                              child: _salvandoComplemento
                                  ? const SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : const Text('Salvar alterações'),
                            ),
                          ] else ...[
                            _infoRow(Icons.phone_outlined, 'Telefone',
                                _telefoneCtrl.text.isEmpty
                                    ? 'Não informado' : _telefoneCtrl.text),
                            const SizedBox(height: 14),
                            const Divider(height: 1),
                            const SizedBox(height: 14),
                            _infoRow(Icons.cake_outlined, 'Data de nascimento',
                                _dataNascimento == null
                                    ? 'Não informada'
                                    : _formatarData(_dataNascimento!)),
                            const SizedBox(height: 14),
                            const Divider(height: 1),
                            const SizedBox(height: 14),
                            _infoRow(Icons.payments_outlined,
                                'Forma de pagamento preferida',
                                _formaPagamentoPref == null
                                    ? 'Não informada'
                                    : (_formasPagamento[_formaPagamentoPref] ??
                                        _formaPagamentoPref!)),
                            const SizedBox(height: 14),
                            const Divider(height: 1),
                            const SizedBox(height: 14),
                            _infoRow(Icons.health_and_safety_outlined,
                                'Observações de saúde',
                                _observacoesCtrl.text.isEmpty
                                    ? 'Nenhuma observação'
                                    : _observacoesCtrl.text),
                          ],
                        ],
                      ),
                    ),

                    if (_erro != null) ...[
                      const SizedBox(height: 12),
                      Text(_erro!, style: const TextStyle(color: PcT.error)),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _infoRow(IconData icon, String label, String valor) => Row(
    children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
            color: PcT.primaryLight,
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: PcT.primary, size: 18),
      ),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: PcT.text2, fontSize: 11)),
          const SizedBox(height: 2),
          Text(valor,
              style: const TextStyle(
                  color: PcT.text1,
                  fontWeight: FontWeight.w500,
                  fontSize: 14)),
        ],
      ),
    ],
  );
}

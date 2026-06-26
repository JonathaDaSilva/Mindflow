import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mindflow_shared/mindflow_shared.dart';
import '../theme/psicologo_theme.dart';

// RF18 — psicólogo bloqueia dias da agenda (ex.: férias, feriado).
// Datas bloqueadas deixam de gerar slots livres para os pacientes
// (ver DisponibilidadeService.buscarSlotsLivres no backend).
class BloqueiosAgendaScreen extends StatefulWidget {
  const BloqueiosAgendaScreen({super.key});

  @override
  State<BloqueiosAgendaScreen> createState() => _BloqueiosAgendaScreenState();
}

class _BloqueiosAgendaScreenState extends State<BloqueiosAgendaScreen> {
  List<Map<String, dynamic>> _bloqueios = [];
  bool _carregando = true;
  bool _salvando = false;

  final _df = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final res = await ApiClient.get('/disponibilidades/bloqueios');
      if (res.statusCode == 200) {
        final lista = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
        lista.sort((a, b) => (a['data'] as String).compareTo(b['data'] as String));
        setState(() => _bloqueios = lista);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _bloquearNovoDia() async {
    final hoje = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: hoje,
      firstDate: hoje,
      lastDate: hoje.add(const Duration(days: 365)),
      helpText: 'Selecione o dia a bloquear',
    );
    if (data == null) return;

    final motivoCtrl = TextEditingController();
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bloquear dia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_df.format(data), style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: motivoCtrl,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional)',
                hintText: 'Ex.: Férias',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Bloquear')),
        ],
      ),
    );
    if (confirmou != true) return;

    setState(() => _salvando = true);
    try {
      final body = {
        'data': DateFormat('yyyy-MM-dd').format(data),
        'motivo': motivoCtrl.text.trim().isEmpty ? null : motivoCtrl.text.trim(),
      };
      final res = await ApiClient.post('/disponibilidades/bloqueios', body);
      if (!mounted) return;
      if (res.statusCode == 201) {
        await _carregar();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Dia bloqueado com sucesso'),
          backgroundColor: PT.success,
        ));
      } else {
        final msg = jsonDecode(res.body)['error'] as String? ?? 'Erro ao bloquear dia';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: PT.error));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Erro ao bloquear dia'),
        backgroundColor: PT.error,
      ));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _desbloquear(String dataIso) async {
    try {
      final res = await ApiClient.delete('/disponibilidades/bloqueios/$dataIso');
      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 204) {
        await _carregar();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bloqueio removido'),
          backgroundColor: PT.success,
        ));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PT.background,
      appBar: AppBar(
        title: const Text('Bloqueio de agenda'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: PT.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded, color: PT.primary, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Dias bloqueados (ex.: férias, feriados) não aparecem '
                  'como horário disponível para os pacientes.',
                  style: TextStyle(color: PT.text2, fontSize: 12, height: 1.4),
                ),
              ),
            ]),
          ),
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator(color: PT.primary))
                : _bloqueios.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: PT.surfaceAlt,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.event_busy_rounded,
                                  color: PT.text3, size: 28),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Nenhum dia bloqueado.',
                              style: TextStyle(color: PT.text2),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _bloqueios.length,
                        itemBuilder: (_, i) {
                          final b = _bloqueios[i];
                          final dataIso = b['data'] as String;
                          final data = DateTime.parse(dataIso);
                          final motivo = b['motivo'] as String?;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: PT.card,
                            padding: const EdgeInsets.all(14),
                            child: Row(children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: PT.errorLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.event_busy_rounded,
                                    color: PT.error, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_df.format(data),
                                        style: const TextStyle(
                                            color: PT.text1,
                                            fontWeight: FontWeight.w600)),
                                    if (motivo != null && motivo.isNotEmpty)
                                      Text(motivo,
                                          style: const TextStyle(
                                              color: PT.text2, fontSize: 12)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: PT.error, size: 20),
                                onPressed: () => _desbloquear(dataIso),
                              ),
                            ]),
                          );
                        },
                      ),
          ),
          Container(
            color: PT.background,
            padding: const EdgeInsets.all(20),
            child: ElevatedButton.icon(
              onPressed: _salvando ? null : _bloquearNovoDia,
              icon: _salvando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add_rounded),
              label: Text(_salvando ? 'Bloqueando...' : 'Bloquear dia'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
          ),
        ],
      ),
    );
  }
}

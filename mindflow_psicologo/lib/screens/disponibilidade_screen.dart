import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mindflow_shared/mindflow_shared.dart';
import '../theme/psicologo_theme.dart';

class DisponibilidadeScreen extends StatefulWidget {
  const DisponibilidadeScreen({super.key});

  @override
  State<DisponibilidadeScreen> createState() => _DisponibilidadeScreenState();
}

class _DisponibilidadeScreenState extends State<DisponibilidadeScreen> {
  final List<_BlocoDisp> _blocos = [];
  bool _salvando   = false;
  bool _carregando = true;

  static const _dias = [
    {'valor': 1, 'label': 'Segunda-feira'},
    {'valor': 2, 'label': 'Terça-feira'},
    {'valor': 3, 'label': 'Quarta-feira'},
    {'valor': 4, 'label': 'Quinta-feira'},
    {'valor': 5, 'label': 'Sexta-feira'},
    {'valor': 6, 'label': 'Sábado'},
    {'valor': 7, 'label': 'Domingo'},
  ];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final res = await ApiClient.get('/disponibilidades');
      if (res.statusCode == 200) {
        final lista = jsonDecode(res.body) as List;
        setState(() {
          _blocos.clear();
          for (final item in lista) {
            final d      = item as Map<String, dynamic>;
            final inicio = d['horaInicio'] as String;
            final fim    = d['horaFim']    as String;
            _blocos.add(_BlocoDisp(
              diaSemana: d['diaSemana'] as int,
              horaInicio: TimeOfDay(
                hour:   int.parse(inicio.split(':')[0]),
                minute: int.parse(inicio.split(':')[1]),
              ),
              horaFim: TimeOfDay(
                hour:   int.parse(fim.split(':')[0]),
                minute: int.parse(fim.split(':')[1]),
              ),
            ));
          }
        });
      }
    } catch (_) {
    } finally {
      setState(() => _carregando = false);
    }
  }

  void _adicionarBloco() {
    setState(() => _blocos.add(_BlocoDisp(
          diaSemana:  1,
          horaInicio: const TimeOfDay(hour: 9, minute: 0),
          horaFim:    const TimeOfDay(hour: 12, minute: 0),
        )));
  }

  void _removerBloco(int i) => setState(() => _blocos.removeAt(i));

  Future<void> _salvar() async {
    if (_blocos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Adicione pelo menos um bloco de horário'),
        backgroundColor: PT.error,
      ));
      return;
    }

    for (final b in _blocos) {
      final ini = b.horaInicio.hour * 60 + b.horaInicio.minute;
      final fim = b.horaFim.hour    * 60 + b.horaFim.minute;
      if (fim <= ini) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Hora fim deve ser após a hora de início'),
          backgroundColor: PT.error,
        ));
        return;
      }
    }

    setState(() => _salvando = true);
    try {
      final body = {
        'disponibilidades': _blocos
            .map((b) => {
                  'diaSemana':  b.diaSemana,
                  'horaInicio': _horaStr(b.horaInicio),
                  'horaFim':    _horaStr(b.horaFim),
                })
            .toList(),
      };
      final res = await ApiClient.put('/disponibilidades', body);
      if (!mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Agenda salva com sucesso!'),
          backgroundColor: PT.success,
        ));
      } else {
        throw Exception('Erro ao salvar');
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Erro ao salvar agenda'),
        backgroundColor: PT.error,
      ));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _selecionarHora(int i, bool isInicio) async {
    final atual  = isInicio ? _blocos[i].horaInicio : _blocos[i].horaFim;
    final picked = await showTimePicker(
      context: context,
      initialTime: atual,
    );
    if (picked != null) {
      setState(() {
        if (isInicio) _blocos[i].horaInicio = picked;
        else          _blocos[i].horaFim    = picked;
      });
    }
  }

  String _nomeDia(int dia) =>
      (_dias.firstWhere((d) => d['valor'] == dia)['label'] as String);

  String _horaStr(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PT.background,
      appBar: AppBar(
        title: const Text('Disponibilidade'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _salvando ? null : _salvar,
            child: _salvando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: PT.primary))
                : const Text('Salvar',
                    style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: PT.primary))
          : Column(
              children: [
                Expanded(
                  child: _blocos.isEmpty
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
                                child: const Icon(
                                    Icons.calendar_today_rounded,
                                    color: PT.text3,
                                    size: 28),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Nenhum horário cadastrado.\nAdicione blocos de disponibilidade.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: PT.text2, height: 1.5),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _blocos.length,
                          itemBuilder: (_, i) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: PT.card,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header do bloco
                                Row(children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: PT.primaryLight,
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.today_rounded,
                                        color: PT.primary, size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Bloco ${i + 1}',
                                    style: const TextStyle(
                                        color: PT.text1,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: PT.error, size: 20),
                                    onPressed: () => _removerBloco(i),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ]),
                                const SizedBox(height: 14),

                                // Dropdown dia
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: PT.surfaceAlt,
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    border: Border.all(
                                        color: PT.border, width: 1),
                                  ),
                                  child: DropdownButton<int>(
                                    value: _blocos[i].diaSemana,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    style: const TextStyle(
                                        color: PT.text1,
                                        fontSize: 14,
                                        fontFamily: 'Inter'),
                                    dropdownColor: PT.surface,
                                    items: _dias
                                        .map((d) => DropdownMenuItem<int>(
                                              value: d['valor'] as int,
                                              child: Text(
                                                  d['label'] as String),
                                            ))
                                        .toList(),
                                    onChanged: (v) => setState(
                                        () => _blocos[i].diaSemana = v!),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Horários
                                Row(children: [
                                  Expanded(
                                    child: _horaBotao(
                                      label: 'Início',
                                      hora:
                                          _horaStr(_blocos[i].horaInicio),
                                      onTap: () =>
                                          _selecionarHora(i, true),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: Icon(
                                      Icons.arrow_forward_rounded,
                                      color: PT.text3,
                                      size: 16,
                                    ),
                                  ),
                                  Expanded(
                                    child: _horaBotao(
                                      label: 'Término',
                                      hora: _horaStr(_blocos[i].horaFim),
                                      onTap: () =>
                                          _selecionarHora(i, false),
                                    ),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                        ),
                ),

                // Botão adicionar
                Container(
                  color: PT.background,
                  padding: const EdgeInsets.all(20),
                  child: OutlinedButton.icon(
                    onPressed: _adicionarBloco,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Adicionar bloco de horário'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _horaBotao({
    required String label,
    required String hora,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: PT.primaryLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: PT.primary.withOpacity(0.2), width: 1),
          ),
          child: Column(children: [
            Text(label,
                style: const TextStyle(
                    color: PT.text2, fontSize: 11)),
            const SizedBox(height: 4),
            Text(hora,
                style: const TextStyle(
                    color: PT.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}

class _BlocoDisp {
  int diaSemana;
  TimeOfDay horaInicio;
  TimeOfDay horaFim;

  _BlocoDisp({
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFim,
  });
}

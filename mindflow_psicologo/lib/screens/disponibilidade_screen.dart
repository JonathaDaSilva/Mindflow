import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mindflow_shared/mindflow_shared.dart';

class DisponibilidadeScreen extends StatefulWidget {
  const DisponibilidadeScreen({super.key});

  @override
  State<DisponibilidadeScreen> createState() => _DisponibilidadeScreenState();
}

class _DisponibilidadeScreenState extends State<DisponibilidadeScreen> {
  final List<_BlocoDisp> _blocos = [];
  bool _salvando  = false;
  bool _carregando = true;
  String? _erro;

  static const _dias = [
    {'valor': 1, 'label': 'Segunda'},
    {'valor': 2, 'label': 'Terça'},
    {'valor': 3, 'label': 'Quarta'},
    {'valor': 4, 'label': 'Quinta'},
    {'valor': 5, 'label': 'Sexta'},
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
            final d = item as Map<String, dynamic>;
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
      // sem agenda ainda — tudo bem
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

  void _removerBloco(int index) {
    setState(() => _blocos.removeAt(index));
  }

  Future<void> _salvar() async {
    if (_blocos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Adicione pelo menos um bloco'),
            backgroundColor: AppTheme.error),
      );
      return;
    }

    // Valida horários
    for (final b in _blocos) {
      final inicioMin = b.horaInicio.hour * 60 + b.horaInicio.minute;
      final fimMin    = b.horaFim.hour    * 60 + b.horaFim.minute;
      if (fimMin <= inicioMin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Hora fim deve ser depois da hora início'),
              backgroundColor: AppTheme.error),
        );
        return;
      }
    }

    setState(() => _salvando = true);

    try {
      final body = {
        'disponibilidades': _blocos.map((b) => {
          'diaSemana':  b.diaSemana,
          'horaInicio': '${b.horaInicio.hour.toString().padLeft(2,'0')}:${b.horaInicio.minute.toString().padLeft(2,'0')}',
          'horaFim':    '${b.horaFim.hour.toString().padLeft(2,'0')}:${b.horaFim.minute.toString().padLeft(2,'0')}',
        }).toList(),
      };

      final res = await ApiClient.put('/disponibilidades', body);
      if (!mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Agenda salva com sucesso! ✅'),
              backgroundColor: AppTheme.success),
        );
      } else {
        throw Exception('Erro ao salvar');
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erro ao salvar agenda'),
            backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _selecionarHora(
      int index, bool isInicio) async {
    final atual = isInicio
        ? _blocos[index].horaInicio
        : _blocos[index].horaFim;
    final picked = await showTimePicker(
      context: context,
      initialTime: atual,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.secondary,
            surface: AppTheme.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isInicio) _blocos[index].horaInicio = picked;
        else          _blocos[index].horaFim    = picked;
      });
    }
  }

  String _nomeDia(int dia) =>
      _dias.firstWhere((d) => d['valor'] == dia)['label'] as String;

  String _horaStr(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';

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
        title: const Text('Minha disponibilidade',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: _salvando ? null : _salvar,
            child: _salvando
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.secondary))
                : const Text('Salvar',
                    style: TextStyle(
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.secondary))
          : Column(
              children: [
                Expanded(
                  child: _blocos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  color: AppTheme.textSecond, size: 48),
                              const SizedBox(height: 12),
                              const Text(
                                  'Nenhum horário cadastrado.\nAdicione blocos de disponibilidade.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: AppTheme.textSecond,
                                      height: 1.5)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: _blocos.length,
                          itemBuilder: (_, i) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                // Dia da semana
                                Row(children: [
                                  const Icon(Icons.today_rounded,
                                      color: AppTheme.secondary, size: 18),
                                  const SizedBox(width: 8),
                                  const Text('Dia da semana',
                                      style: TextStyle(
                                          color: AppTheme.textSecond,
                                          fontSize: 13)),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: AppTheme.error, size: 20),
                                    onPressed: () => _removerBloco(i),
                                  ),
                                ]),
                                const SizedBox(height: 8),
                                // Dropdown dia
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceAlt,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: DropdownButton<int>(
                                    value: _blocos[i].diaSemana,
                                    isExpanded: true,
                                    underline: const SizedBox(),
                                    dropdownColor: AppTheme.surfaceAlt,
                                    style: const TextStyle(
                                        color: AppTheme.textPrimary),
                                    items: _dias.map((d) =>
                                      DropdownMenuItem<int>(
                                        value: d['valor'] as int,
                                        child: Text(d['label'] as String),
                                      )).toList(),
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
                                      hora:  _horaStr(_blocos[i].horaInicio),
                                      onTap: () => _selecionarHora(i, true),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.arrow_forward,
                                      color: AppTheme.textSecond, size: 16),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _horaBotao(
                                      label: 'Fim',
                                      hora:  _horaStr(_blocos[i].horaFim),
                                      onTap: () => _selecionarHora(i, false),
                                    ),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                        ),
                ),

                // Botão adicionar
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: OutlinedButton.icon(
                    onPressed: _adicionarBloco,
                    icon: const Icon(Icons.add_rounded,
                        color: AppTheme.secondary),
                    label: const Text('Adicionar bloco de horário',
                        style: TextStyle(color: AppTheme.secondary)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      side: BorderSide(
                          color: AppTheme.secondary.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
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
            color: AppTheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppTheme.secondary.withOpacity(0.3)),
          ),
          child: Column(children: [
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecond, fontSize: 11)),
            const SizedBox(height: 4),
            Text(hora,
                style: const TextStyle(
                    color: AppTheme.secondary,
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
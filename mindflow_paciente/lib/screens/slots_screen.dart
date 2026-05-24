import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mindflow_shared/mindflow_shared.dart';

class SlotsScreen extends StatefulWidget {
  final String psicologoId;
  final String nomePsicologo;

  const SlotsScreen({
    super.key,
    required this.psicologoId,
    required this.nomePsicologo,
  });

  @override
  State<SlotsScreen> createState() => _SlotsScreenState();
}

class _SlotsScreenState extends State<SlotsScreen> {
  DateTime _dataSelecionada = DateTime.now();
  List<Map<String, dynamic>> _slots = [];
  bool _loading = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _buscarSlots(_dataSelecionada);
  }

  Future<void> _buscarSlots(DateTime data) async {
    setState(() {
      _loading = true;
      _erro = null;
      _slots = [];
    });
    try {
      final dataStr =
          '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
      final res = await ApiClient.get(
          '/disponibilidades/${widget.psicologoId}/slots?data=$dataStr');

      if (res.statusCode == 200) {
        final lista = jsonDecode(res.body) as List;
        setState(() =>
            _slots = lista.map((e) => e as Map<String, dynamic>).toList());
      } else {
        setState(() => _erro = 'Erro ao buscar horários');
      }
    } catch (e) {
      setState(() => _erro = 'Verifique sua conexão');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primary,
            surface: AppTheme.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dataSelecionada = picked);
      _buscarSlots(picked);
    }
  }

  String _formatarData(DateTime data) {
    const dias = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    const meses = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez'
    ];
    return '${dias[data.weekday % 7]}, ${data.day} de ${meses[data.month - 1]}';
  }

  Future<void> _agendarConsulta(String dataHora, String horaFormatada) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Confirmar agendamento',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Agendar consulta com ${widget.nomePsicologo}\n'
          'Data: ${_formatarData(_dataSelecionada)}\n'
          'Horário: $horaFormatada',
          style: const TextStyle(color: AppTheme.textSecond, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppTheme.textSecond)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final res = await ApiClient.post('/consultas', {
        'psicologoId': widget.psicologoId,
        'dataHora': dataHora,
        'formaPagamento': 'PIX',
      });

      if (!mounted) return;

      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consulta solicitada com sucesso! ✅'),
            backgroundColor: AppTheme.success,
          ),
        );
        _buscarSlots(_dataSelecionada); // atualiza slots
      } else {
        final erro = jsonDecode(res.body)['error'] ?? 'Erro ao agendar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(erro),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro de conexão'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
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
        title: Text(widget.nomePsicologo,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Seletor de data
            Padding(
              padding: const EdgeInsets.all(24),
              child: GestureDetector(
                onTap: _selecionarData,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: AppTheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _formatarData(_dataSelecionada),
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textSecond),
                  ]),
                ),
              ),
            ),

            // Slots
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary))
                  : _erro != null
                      ? Center(
                          child: Text(_erro!,
                              style:
                                  const TextStyle(color: AppTheme.textSecond)))
                      : _slots.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.event_busy_rounded,
                                      color: AppTheme.textSecond, size: 48),
                                  const SizedBox(height: 12),
                                  const Text(
                                      'Sem horários disponíveis\nneste dia',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: AppTheme.textSecond,
                                          height: 1.5)),
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: _selecionarData,
                                    child: const Text('Escolher outra data',
                                        style:
                                            TextStyle(color: AppTheme.primary)),
                                  ),
                                ],
                              ),
                            )
                          : Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_slots.length} horário${_slots.length > 1 ? 's' : ''} disponível${_slots.length > 1 ? 'is' : ''}',
                                    style: const TextStyle(
                                        color: AppTheme.textSecond,
                                        fontSize: 13),
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: GridView.builder(
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                        childAspectRatio: 1.8,
                                      ),
                                      itemCount: _slots.length,
                                      itemBuilder: (_, i) {
                                        final slot = _slots[i];
                                        final hora =
                                            slot['horaFormatada'] as String;
                                        final dataHora =
                                            slot['dataHora'] as String;
                                        return GestureDetector(
                                          onTap: () =>
                                              _agendarConsulta(dataHora, hora),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: AppTheme.primary
                                                  .withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: AppTheme.primary
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(hora,
                                                  style: const TextStyle(
                                                      color: AppTheme.primary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 15)),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

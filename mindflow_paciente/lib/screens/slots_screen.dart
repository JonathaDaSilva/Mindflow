// mindflow_paciente/lib/screens/slots_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mindflow_shared/mindflow_shared.dart';

class SlotsScreen extends StatefulWidget {
  final String psicologoId;
  final String nomePsicologo;
  final DateTime dataInicial;

  const SlotsScreen({
    super.key,
    required this.psicologoId,
    required this.nomePsicologo,
    required this.dataInicial,
  });

  @override
  State<SlotsScreen> createState() => _SlotsScreenState();
}

class _SlotsScreenState extends State<SlotsScreen> {
  late DateTime _dataSelecionada;
  List<Map<String, dynamic>> _slots = [];
  bool _loading = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _dataSelecionada = widget.dataInicial;
    _buscarSlots(_dataSelecionada);
  }

  Future<void> _buscarSlots(DateTime data) async {
    setState(() { _loading = true; _erro = null; _slots = []; });
    try {
      final dataStr =
          '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
      final res = await ApiClient.get(
          '/disponibilidades/${widget.psicologoId}/slots?data=$dataStr');
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          setState(() =>
              _slots = decoded.map((e) => e as Map<String, dynamic>).toList());
        }
      } else if (res.statusCode == 204) {
        setState(() => _slots = []);
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        setState(() => _erro = 'Sessão expirada. Faça login novamente.');
      } else {
        setState(() => _erro = 'Erro ${res.statusCode} ao buscar horários');
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
      builder: (ctx, child) => Theme(
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

  Future<void> _agendarConsulta(String dataHora, String horaFormatada) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmar agendamento',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Psicólogo: ${widget.nomePsicologo}\n'
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

    // Feedback imediato enquanto aguarda
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(children: [
          SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white)),
          SizedBox(width: 12),
          Text('Agendando consulta...'),
        ]),
        duration: Duration(seconds: 15),
        backgroundColor: AppTheme.primary,
      ),
    );

    try {
      final res = await ApiClient.post('/consultas', {
        'psicologoId': widget.psicologoId,
        'dataHora': dataHora,       // "2026-06-05T14:00:00"
        'formaPagamento': 'PIX',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (res.statusCode == 201 || res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consulta agendada com sucesso! ✅'),
            backgroundColor: AppTheme.success,
            duration: Duration(seconds: 3),
          ),
        );
        _buscarSlots(_dataSelecionada);
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sessão expirada. Faça login novamente.'),
            backgroundColor: AppTheme.error,
          ),
        );
      } else if (res.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Horário já reservado. Escolha outro.'),
            backgroundColor: AppTheme.error,
          ),
        );
        _buscarSlots(_dataSelecionada);
      } else {
        final erro = _extrairErro(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ${res.statusCode}: $erro'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro de conexão. Verifique sua internet.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  String _extrairErro(String body) {
    try {
      final m = jsonDecode(body) as Map<String, dynamic>;
      return (m['error'] ?? m['message'] ?? 'Erro desconhecido').toString();
    } catch (_) {
      return body.isEmpty ? 'Erro desconhecido' : body;
    }
  }

  String _formatarData(DateTime d) {
    const dias = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    const meses = ['Jan','Fev','Mar','Abr','Mai','Jun',
                   'Jul','Ago','Set','Out','Nov','Dez'];
    return '${dias[d.weekday % 7]}, ${d.day} de ${meses[d.month - 1]}';
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: AppTheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Data selecionada',
                              style: TextStyle(
                                  color: AppTheme.textSecond, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(_formatarData(_dataSelecionada),
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textSecond),
                  ]),
                ),
              ),
            ),

            // Conteúdo
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primary))
                  : _erro != null
                      ? _ErroView(
                          mensagem: _erro!,
                          onRetry: () => _buscarSlots(_dataSelecionada),
                          onOutraData: _selecionarData,
                        )
                      : _slots.isEmpty
                          ? _SemHorariosView(onOutraData: _selecionarData)
                          : _SlotsGrid(
                              slots: _slots,
                              onAgendar: _agendarConsulta,
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _ErroView extends StatelessWidget {
  final String mensagem;
  final VoidCallback onRetry;
  final VoidCallback onOutraData;

  const _ErroView({
      required this.mensagem,
      required this.onRetry,
      required this.onOutraData});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppTheme.error, size: 48),
            const SizedBox(height: 12),
            Text(mensagem,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.textSecond, height: 1.5)),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              OutlinedButton(
                  onPressed: onOutraData,
                  child: const Text('Outra data')),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Tentar novamente')),
            ]),
          ],
        ),
      ),
    );
  }
}

class _SemHorariosView extends StatelessWidget {
  final VoidCallback onOutraData;
  const _SemHorariosView({required this.onOutraData});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_busy_rounded,
              color: AppTheme.textSecond, size: 48),
          const SizedBox(height: 12),
          const Text('Sem horários disponíveis\nneste dia',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecond, height: 1.5)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onOutraData,
            child: const Text('Escolher outra data',
                style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }
}

class _SlotsGrid extends StatelessWidget {
  final List<Map<String, dynamic>> slots;
  final void Function(String dataHora, String hora) onAgendar;

  const _SlotsGrid({required this.slots, required this.onAgendar});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${slots.length} horário${slots.length > 1 ? 's' : ''} '
            'disponível${slots.length > 1 ? 'is' : ''}',
            style: const TextStyle(color: AppTheme.textSecond, fontSize: 13),
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
              itemCount: slots.length,
              itemBuilder: (_, i) {
                final slot = slots[i];
                final hora = slot['horaFormatada'] as String;
                final dataHora = slot['dataHora'] as String;
                return GestureDetector(
                  onTap: () => onAgendar(dataHora, hora),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.primary.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text(hora,
                          style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
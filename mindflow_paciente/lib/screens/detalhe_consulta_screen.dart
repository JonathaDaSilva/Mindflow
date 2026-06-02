import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mindflow_shared/mindflow_shared.dart';

class DetalheConsultaScreen extends StatefulWidget {
  final String consultaId;

  const DetalheConsultaScreen({
    super.key,
    required this.consultaId,
  });

  @override
  State<DetalheConsultaScreen> createState() =>
      _DetalheConsultaScreenState();
}

class _DetalheConsultaScreenState
    extends State<DetalheConsultaScreen> {
  Map<String, dynamic>? _consulta;
  bool _loading    = true;
  bool _cancelando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final res =
          await ApiClient.get('/consultas/${widget.consultaId}');
      if (res.statusCode == 200) {
        setState(() =>
            _consulta = jsonDecode(res.body) as Map<String, dynamic>);
      } else {
        setState(() => _erro = 'Consulta não encontrada');
      }
    } catch (_) {
      setState(() => _erro = 'Erro de conexão');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _cancelar() async {
    final motivoCtrl = TextEditingController();

    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Cancelar consulta',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informe o motivo do cancelamento.\n'
              'Lembre-se: só é possível cancelar com\n'
              'mais de 24h de antecedência.',
              style: TextStyle(
                  color: AppTheme.textSecond, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: motivoCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Ex: Imprevisto pessoal',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Voltar',
                style: TextStyle(color: AppTheme.textSecond)),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, motivoCtrl.text.trim()),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error),
            child: const Text('Confirmar cancelamento'),
          ),
        ],
      ),
    );

    if (motivo == null || motivo.isEmpty) return;

    setState(() => _cancelando = true);
    try {
      final res = await ApiClient.patch(
        '/consultas/${widget.consultaId}/cancelar',
        {'motivo': motivo},
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consulta cancelada'),
            backgroundColor: AppTheme.error,
          ),
        );
        Navigator.pop(context); // volta para a lista
      } else {
        final erro =
            jsonDecode(res.body)['error'] ?? 'Erro ao cancelar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(erro),
              backgroundColor: AppTheme.error),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erro de conexão'),
            backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _cancelando = false);
    }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'SOLICITADA':   return Colors.orange;
      case 'CONFIRMADA':   return AppTheme.success;
      case 'RECUSADA':
      case 'CANCELADA':    return AppTheme.error;
      case 'EM_ANDAMENTO': return AppTheme.secondary;
      case 'CONCLUIDA':    return AppTheme.primary;
      default:             return AppTheme.textSecond;
    }
  }

  String _formatarDataHora(String? dh) {
    if (dh == null) return '';
    try {
      final dt = DateTime.parse(dh);
      const dias = [
        'Domingo','Segunda-feira','Terça-feira','Quarta-feira',
        'Quinta-feira','Sexta-feira','Sábado'
      ];
      const meses = [
        'Janeiro','Fevereiro','Março','Abril','Maio','Junho',
        'Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'
      ];
      return '${dias[dt.weekday % 7]}, ${dt.day} de '
             '${meses[dt.month - 1]} de ${dt.year}\n'
             'às ${dt.hour.toString().padLeft(2,'0')}:'
             '${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return dh; }
  }

  bool _podeCancelar(String? status, String? dataHora) {
    if (status == 'CANCELADA' ||
        status == 'RECUSADA' ||
        status == 'CONCLUIDA') return false;
    if (dataHora == null) return false;
    try {
      final dt = DateTime.parse(dataHora);
      return dt.difference(DateTime.now()).inHours >= 24;
    } catch (_) { return false; }
  }

  @override
  Widget build(BuildContext context) {
    final status  = _consulta?['status']       as String?;
    final dh      = _consulta?['dataHora']     as String?;
    final psi     = _consulta?['nomePsicologo'] as String? ?? '';
    final obs     = _consulta?['observacao']   as String?;
    final motivo  = _consulta?['motivoCancelamento'] as String?;
    final pagto   = _consulta?['formaPagamento'] as String?;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Detalhe da Consulta',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primary))
          : _erro != null
              ? Center(
                  child: Text(_erro!,
                      style: const TextStyle(
                          color: AppTheme.textSecond)))
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card de status
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _statusColor(status)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _statusColor(status)
                                    .withOpacity(0.3)),
                          ),
                          child: Column(children: [
                            Icon(
                              status == 'CONFIRMADA'
                                  ? Icons.check_circle_rounded
                                  : status == 'CANCELADA' ||
                                          status == 'RECUSADA'
                                      ? Icons.cancel_rounded
                                      : status == 'CONCLUIDA'
                                          ? Icons.task_alt_rounded
                                          : Icons.schedule_rounded,
                              color: _statusColor(status),
                              size: 48,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              status ?? '',
                              style: TextStyle(
                                  color: _statusColor(status),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700),
                            ),
                          ]),
                        ),

                        const SizedBox(height: 24),

                        // Informações
                        _secao('Psicólogo',
                            Icons.person_outline, psi),
                        _secao('Data e horário',
                            Icons.calendar_today_rounded,
                            _formatarDataHora(dh)),
                        if (pagto != null)
                          _secao('Forma de pagamento',
                              Icons.payment_rounded, pagto),
                        if (obs != null && obs.isNotEmpty)
                          _secao('Observação',
                              Icons.notes_rounded, obs),
                        if (motivo != null && motivo.isNotEmpty)
                          _secao('Motivo do cancelamento',
                              Icons.info_outline, motivo,
                              cor: AppTheme.error),

                        // Status CONFIRMADA — mostra link se remoto
                        if (status == 'CONFIRMADA') ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.success
                                  .withOpacity(0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(children: [
                              const Icon(
                                  Icons.video_call_rounded,
                                  color: AppTheme.success,
                                  size: 20),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'O psicólogo irá enviar o link\nda sala até 24h antes da sessão.',
                                  style: TextStyle(
                                      color: AppTheme.success,
                                      fontSize: 13,
                                      height: 1.4),
                                ),
                              ),
                            ]),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Botão cancelar
                        if (_podeCancelar(status, dh))
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed:
                                  _cancelando ? null : _cancelar,
                              icon: _cancelando
                                  ? const SizedBox(
                                      width: 16, height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.error))
                                  : const Icon(Icons.cancel_outlined,
                                      color: AppTheme.error),
                              label: Text(
                                _cancelando
                                    ? 'Cancelando...'
                                    : 'Cancelar consulta',
                                style: const TextStyle(
                                    color: AppTheme.error),
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize:
                                    const Size(double.infinity, 52),
                                side: BorderSide(
                                    color: AppTheme.error
                                        .withOpacity(0.5)),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(16)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _secao(String titulo, IconData icon, String valor,
      {Color? cor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              color: cor ?? AppTheme.textSecond, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        color: AppTheme.textSecond,
                        fontSize: 11)),
                const SizedBox(height: 4),
                Text(valor,
                    style: TextStyle(
                        color: cor ?? AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
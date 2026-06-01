import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mindflow_shared/mindflow_shared.dart';

class ConsultasScreen extends StatefulWidget {
  const ConsultasScreen({super.key});

  @override
  State<ConsultasScreen> createState() => _ConsultasScreenState();
}

class _ConsultasScreenState extends State<ConsultasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Map<String, dynamic>> _pendentes  = [];
  List<Map<String, dynamic>> _todas      = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final r1 = await ApiClient.get('/consultas/pendentes');
      final r2 = await ApiClient.get('/consultas/agenda');
      setState(() {
        _pendentes = r1.statusCode == 200
            ? (jsonDecode(r1.body) as List)
                .map((e) => e as Map<String, dynamic>)
                .toList()
            : [];
        _todas = r2.statusCode == 200
            ? (jsonDecode(r2.body) as List)
                .map((e) => e as Map<String, dynamic>)
                .toList()
            : [];
      });
    } catch (_) {}
    finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _atualizarStatus(String id, String status) async {
    try {
      final res = await ApiClient.patch(
        '/consultas/$id/status',
        {'status': status},
      );
      if (res.statusCode == 200) {
        _carregar();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(status == 'CONFIRMADA'
              ? 'Consulta confirmada! ✅'
              : 'Consulta recusada'),
          backgroundColor: status == 'CONFIRMADA'
              ? AppTheme.success
              : AppTheme.error,
        ));
      }
    } catch (_) {}
  }

  Future<void> _cancelar(String id) async {
    final motivo = await _pedirMotivo();
    if (motivo == null) return;

    try {
      final res = await ApiClient.patch(
        '/consultas/$id/cancelar',
        {'motivo': motivo},
      );
      if (res.statusCode == 200) {
        _carregar();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consulta cancelada'),
              backgroundColor: AppTheme.error),
        );
      } else {
        final erro = jsonDecode(res.body)['error'] ?? '';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(erro),
              backgroundColor: AppTheme.error),
        );
      }
    } catch (_) {}
  }

  Future<String?> _pedirMotivo() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Motivo do cancelamento',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Informe o motivo...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar',
                style: TextStyle(color: AppTheme.textSecond)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error),
            child: const Text('Confirmar cancelamento'),
          ),
        ],
      ),
    );
  }

  String _formatarDataHora(String? dh) {
    if (dh == null) return '';
    try {
      final dt = DateTime.parse(dh);
      const dias = ['Dom','Seg','Ter','Qua','Qui','Sex','Sáb'];
      const meses = ['Jan','Fev','Mar','Abr','Mai','Jun',
                     'Jul','Ago','Set','Out','Nov','Dez'];
      return '${dias[dt.weekday % 7]}, ${dt.day} ${meses[dt.month - 1]} às ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return dh;
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

  @override
  void dispose() {
    _tabs.dispose();
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
        title: const Text('Consultas',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppTheme.textSecond),
            onPressed: _carregar,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppTheme.secondary,
          labelColor: AppTheme.secondary,
          unselectedLabelColor: AppTheme.textSecond,
          tabs: [
            Tab(text: 'Pendentes (${_pendentes.length})'),
            Tab(text: 'Todas (${_todas.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.secondary))
          : TabBarView(
              controller: _tabs,
              children: [
                // Tab pendentes — com botões confirmar/recusar
                _listaConsultas(
                  _pendentes,
                  mostrarAcoes: true,
                ),
                // Tab todas
                _listaConsultas(
                  _todas,
                  mostrarAcoes: false,
                ),
              ],
            ),
    );
  }

  Widget _listaConsultas(
    List<Map<String, dynamic>> lista, {
    required bool mostrarAcoes,
  }) {
    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              mostrarAcoes
                  ? Icons.check_circle_outline
                  : Icons.event_note_rounded,
              color: AppTheme.textSecond, size: 48),
            const SizedBox(height: 12),
            Text(
              mostrarAcoes
                  ? 'Nenhuma solicitação pendente'
                  : 'Nenhuma consulta encontrada',
              style: const TextStyle(color: AppTheme.textSecond),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      color: AppTheme.secondary,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: lista.length,
        itemBuilder: (_, i) {
          final c       = lista[i];
          final id      = c['id']           as String;
          final paciente = c['nomePaciente'] as String? ?? '';
          final dh      = c['dataHora']     as String?;
          final status  = c['status']       as String?;
          final obs     = c['observacao']   as String?;

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        paciente.isNotEmpty
                            ? paciente[0].toUpperCase() : '?',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(paciente,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary)),
                        Text(_formatarDataHora(dh),
                            style: const TextStyle(
                                color: AppTheme.textSecond,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                  // Badge status
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status ?? '',
                      style: TextStyle(
                          color: _statusColor(status),
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),

                if (obs != null && obs.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.notes_rounded,
                          color: AppTheme.textSecond, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(obs,
                            style: const TextStyle(
                                color: AppTheme.textSecond,
                                fontSize: 13,
                                height: 1.4)),
                      ),
                    ]),
                  ),
                ],

                if (mostrarAcoes) ...[
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            _atualizarStatus(id, 'RECUSADA'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: AppTheme.error.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Recusar',
                            style: TextStyle(color: AppTheme.error)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            _atualizarStatus(id, 'CONFIRMADA'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Confirmar'),
                      ),
                    ),
                  ]),
                ] else if (status == 'CONFIRMADA') ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _cancelar(id),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: AppTheme.error.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancelar consulta',
                          style: TextStyle(color: AppTheme.error)),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
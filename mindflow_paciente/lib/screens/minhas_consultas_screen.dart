import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mindflow_shared/mindflow_shared.dart';
import 'detalhe_consulta_screen.dart';
import '../services/consulta_monitor_service.dart';

class MinhasConsultasScreen extends StatefulWidget {
  const MinhasConsultasScreen({super.key});

  @override
  State<MinhasConsultasScreen> createState() =>
      _MinhasConsultasScreenState();
}

class _MinhasConsultasScreenState
    extends State<MinhasConsultasScreen> {
  List<Map<String, dynamic>> _consultas = [];
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    // Monitor MOM — atualiza lista quando backend processa evento
    ConsultaMonitorService.adicionarListener(_onConsultasAtualizadas);
    ConsultaMonitorService.verificarAgora();
    _carregar();
  }

  @override
  void dispose() {
    ConsultaMonitorService.removerListener(_onConsultasAtualizadas);
    super.dispose();
  }

  void _onConsultasAtualizadas(
      List<Map<String, dynamic>> consultas) {
    if (!mounted) return;
    final lista = List<Map<String, dynamic>>.from(consultas);
    lista.sort((a, b) {
      final da =
          DateTime.tryParse(a['dataHora'] ?? '') ?? DateTime(0);
      final db =
          DateTime.tryParse(b['dataHora'] ?? '') ?? DateTime(0);
      return db.compareTo(da);
    });
    setState(() {
      _consultas = lista;
      _loading   = false;
    });
  }

  Future<void> _carregar() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final res = await ApiClient.get('/consultas/minhas');
      if (res.statusCode == 200) {
        final lista = (jsonDecode(res.body) as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        lista.sort((a, b) {
          final da =
              DateTime.tryParse(a['dataHora'] ?? '') ?? DateTime(0);
          final db =
              DateTime.tryParse(b['dataHora'] ?? '') ?? DateTime(0);
          return db.compareTo(da);
        });
        setState(() => _consultas = lista);
      } else {
        setState(() => _erro = 'Erro ao carregar consultas');
      }
    } catch (_) {
      setState(() => _erro = 'Verifique sua conexão');
    } finally {
      setState(() => _loading = false);
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

  IconData _statusIcon(String? s) {
    switch (s) {
      case 'SOLICITADA':   return Icons.schedule_rounded;
      case 'CONFIRMADA':   return Icons.check_circle_outline;
      case 'RECUSADA':
      case 'CANCELADA':    return Icons.cancel_outlined;
      case 'EM_ANDAMENTO': return Icons.play_circle_outline;
      case 'CONCLUIDA':    return Icons.task_alt_rounded;
      default:             return Icons.help_outline;
    }
  }

  String _formatarDataHora(String? dh) {
    if (dh == null) return '';
    try {
      final dt = DateTime.parse(dh);
      const dias   = ['Dom','Seg','Ter','Qua','Qui','Sex','Sáb'];
      const meses  = ['Jan','Fev','Mar','Abr','Mai','Jun',
                      'Jul','Ago','Set','Out','Nov','Dez'];
      return '${dias[dt.weekday % 7]}, ${dt.day} '
             '${meses[dt.month - 1]} · '
             '${dt.hour.toString().padLeft(2,'0')}:'
             '${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return dh; }
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
        title: const Text(
          'Minhas Consultas',
          style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppTheme.textSecond),
            onPressed: _carregar,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primary))
          : _erro != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppTheme.error, size: 48),
                      const SizedBox(height: 12),
                      Text(_erro!,
                          style: const TextStyle(
                              color: AppTheme.textSecond)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _carregar,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _consultas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              color: AppTheme.textSecond, size: 48),
                          const SizedBox(height: 12),
                          const Text(
                            'Você ainda não tem consultas',
                            style:
                                TextStyle(color: AppTheme.textSecond),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.search_rounded),
                            label:
                                const Text('Buscar psicólogos'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _carregar,
                      color: AppTheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _consultas.length,
                        itemBuilder: (_, i) {
                          final c         = _consultas[i];
                          final id        = c['id'] as String;
                          final psicologo =
                              c['nomePsicologo'] as String? ?? '';
                          final dh    = c['dataHora'] as String?;
                          final status = c['status']  as String?;

                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DetalheConsultaScreen(
                                  consultaId: id,
                                ),
                              ),
                            ).then((_) => _carregar()),
                            child: Container(
                              margin:
                                  const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius:
                                    BorderRadius.circular(18),
                                border: Border(
                                  left: BorderSide(
                                    color: _statusColor(status),
                                    width: 3,
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.all(18),
                              child: Row(children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _statusColor(status)
                                        .withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _statusIcon(status),
                                    color: _statusColor(status),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        psicologo,
                                        style: const TextStyle(
                                            fontWeight:
                                                FontWeight.w600,
                                            color:
                                                AppTheme.textPrimary,
                                            fontSize: 15),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatarDataHora(dh),
                                        style: const TextStyle(
                                            color:
                                                AppTheme.textSecond,
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _statusColor(status)
                                            .withOpacity(0.12),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        status ?? '',
                                        style: TextStyle(
                                            color:
                                                _statusColor(status),
                                            fontSize: 11,
                                            fontWeight:
                                                FontWeight.w600),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: AppTheme.textSecond,
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mindflow_shared/mindflow_shared.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  DateTime _focado      = DateTime.now();
  DateTime _selecionado = DateTime.now();
  Map<DateTime, List<Map<String, dynamic>>> _eventos = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final res = await ApiClient.get('/consultas/agenda');
      if (res.statusCode == 200) {
        final lista = (jsonDecode(res.body) as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();

        final Map<DateTime, List<Map<String, dynamic>>> mapa = {};
        for (final c in lista) {
          final dh = c['dataHora'] as String?;
          if (dh == null) continue;
          final dt    = DateTime.parse(dh);
          final chave = DateTime(dt.year, dt.month, dt.day);
          mapa.putIfAbsent(chave, () => []).add(c);
        }
        setState(() => _eventos = mapa);
      }
    } catch (_) {}
    finally {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _eventosNoDia(DateTime dia) =>
      _eventos[DateTime(dia.year, dia.month, dia.day)] ?? [];

  String _formatarHora(String? dh) {
    if (dh == null) return '';
    try {
      final dt = DateTime.parse(dh);
      return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return ''; }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'SOLICITADA':    return Colors.orange;
      case 'CONFIRMADA':    return AppTheme.success;
      case 'RECUSADA':
      case 'CANCELADA':     return AppTheme.error;
      case 'EM_ANDAMENTO':  return AppTheme.secondary;
      case 'CONCLUIDA':     return AppTheme.primary;
      default:              return AppTheme.textSecond;
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventosHoje = _eventosNoDia(_selecionado);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Minha Agenda',
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
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.secondary))
          : NestedScrollView(
              // ← substitui Column, resolve o overflow
              headerSliverBuilder: (_, __) => [
                SliverToBoxAdapter(
                  child: TableCalendar(
                    locale: 'pt_BR',
                    firstDay: DateTime.now()
                        .subtract(const Duration(days: 365)),
                    lastDay: DateTime.now()
                        .add(const Duration(days: 365)),
                    focusedDay: _focado,
                    selectedDayPredicate: (d) =>
                        isSameDay(_selecionado, d),
                    eventLoader: _eventosNoDia,
                    calendarFormat: CalendarFormat.month,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    onDaySelected: (sel, foc) => setState(() {
                      _selecionado = sel;
                      _focado      = foc;
                    }),
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      defaultTextStyle: const TextStyle(
                          color: AppTheme.textPrimary),
                      weekendTextStyle: const TextStyle(
                          color: AppTheme.textSecond),
                      selectedDecoration: const BoxDecoration(
                        color: AppTheme.secondary,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: AppTheme.secondary.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16),
                      leftChevronIcon: Icon(Icons.chevron_left,
                          color: AppTheme.textSecond),
                      rightChevronIcon: Icon(Icons.chevron_right,
                          color: AppTheme.textSecond),
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                          color: AppTheme.textSecond, fontSize: 12),
                      weekendStyle: TextStyle(
                          color: AppTheme.textSecond, fontSize: 12),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Divider(
                      color: AppTheme.surfaceAlt, height: 1),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      eventosHoje.isEmpty
                          ? 'Nenhuma consulta neste dia'
                          : '${eventosHoje.length} consulta${eventosHoje.length > 1 ? 's' : ''} agendada${eventosHoje.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                          color: AppTheme.textSecond,
                          fontSize: 13),
                    ),
                  ),
                ),
              ],
              body: eventosHoje.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.event_available_rounded,
                              color: AppTheme.textSecond, size: 40),
                          const SizedBox(height: 10),
                          Text(
                            'Livre em ${_selecionado.day}/${_selecionado.month}/${_selecionado.year}',
                            style: const TextStyle(
                                color: AppTheme.textSecond),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: eventosHoje.length,
                      itemBuilder: (_, i) {
                        final c        = eventosHoje[i];
                        final paciente = c['nomePaciente'] as String? ?? '';
                        final hora     = _formatarHora(c['dataHora'] as String?);
                        final status   = c['status']    as String?;
                        final obs      = c['observacao'] as String?;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border(
                              left: BorderSide(
                                  color: _statusColor(status),
                                  width: 3),
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            SizedBox(
                              width: 52,
                              child: Text(hora,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: AppTheme.secondary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16)),
                            ),
                            const SizedBox(width: 12),
                            Container(
                                width: 1,
                                height: 40,
                                color: AppTheme.surfaceAlt),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(paciente,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary)),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _statusColor(status)
                                            .withOpacity(0.12),
                                        borderRadius:
                                            BorderRadius.circular(8),
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
                                    const SizedBox(height: 6),
                                    Text(obs,
                                        style: const TextStyle(
                                            color: AppTheme.textSecond,
                                            fontSize: 12,
                                            height: 1.4)),
                                  ],
                                ],
                              ),
                            ),
                          ]),
                        );
                      },
                    ),
            ),
    );
  }
}
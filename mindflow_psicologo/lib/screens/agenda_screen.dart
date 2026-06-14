import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:mindflow_shared/mindflow_shared.dart';
import '../theme/psicologo_theme.dart';

class AgendaScreen extends StatefulWidget {
  final bool isTab;

  const AgendaScreen({super.key, this.isTab = false});

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
            .cast<Map<String, dynamic>>();

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
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _eventosNoDia(DateTime dia) =>
      _eventos[DateTime(dia.year, dia.month, dia.day)] ?? [];

  String _formatarHora(String? dh) {
    if (dh == null) return '';
    try {
      final dt = DateTime.parse(dh);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventosHoje = _eventosNoDia(_selecionado);

    return Scaffold(
      backgroundColor: PT.background,
      appBar: AppBar(
        title: const Text('Minha Agenda'),
        leading: widget.isTab
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pop(context),
              ),
        automaticallyImplyLeading: !widget.isTab,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _carregar,
            color: PT.text2,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: PT.primary))
          : NestedScrollView(
              headerSliverBuilder: (_, __) => [
                SliverToBoxAdapter(
                  child: Container(
                    color: PT.surface,
                    child: TableCalendar(
                      locale: 'pt_BR',
                      firstDay:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDay:
                          DateTime.now().add(const Duration(days: 365)),
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
                        defaultTextStyle:
                            const TextStyle(color: PT.text1, fontSize: 13),
                        weekendTextStyle:
                            const TextStyle(color: PT.text2, fontSize: 13),
                        todayTextStyle: const TextStyle(
                            color: PT.primary, fontWeight: FontWeight.w700, fontSize: 13),
                        selectedTextStyle: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                        selectedDecoration: const BoxDecoration(
                          color: PT.primary,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: PT.primaryLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: PT.primary, width: 1.5),
                        ),
                        markerDecoration: const BoxDecoration(
                          color: PT.accent,
                          shape: BoxShape.circle,
                        ),
                        markerSize: 5,
                        outsideTextStyle:
                            const TextStyle(color: PT.text3, fontSize: 13),
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                            color: PT.text1,
                            fontWeight: FontWeight.w600,
                            fontSize: 15),
                        leftChevronIcon:
                            Icon(Icons.chevron_left, color: PT.text2),
                        rightChevronIcon:
                            Icon(Icons.chevron_right, color: PT.text2),
                        headerPadding:
                            EdgeInsets.symmetric(vertical: 12),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                            color: PT.text2,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                        weekendStyle: TextStyle(
                            color: PT.text3,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    color: PT.background,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(children: [
                      Text(
                        eventosHoje.isEmpty
                            ? 'Nenhuma consulta neste dia'
                            : '${eventosHoje.length} consulta${eventosHoje.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                            color: PT.text2,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ]),
                  ),
                ),
              ],
              body: eventosHoje.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: PT.surfaceAlt,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.event_available_rounded,
                                color: PT.text3, size: 26),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Dia livre — ${_selecionado.day}/${_selecionado.month}',
                            style: const TextStyle(
                                color: PT.text2, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                      itemCount: eventosHoje.length,
                      itemBuilder: (_, i) {
                        final c        = eventosHoje[i];
                        final paciente = c['nomePaciente'] as String? ?? '';
                        final hora     = _formatarHora(c['dataHora'] as String?);
                        final status   = c['status']    as String?;
                        final obs      = c['observacao'] as String?;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: PT.cardWith(
                            accent: PT.statusFg(status),
                          ),
                          child: IntrinsicHeight(
                            child: Row(children: [
                              // Barra colorida lateral
                              Container(
                                width: 4,
                                decoration: BoxDecoration(
                                  color: PT.statusFg(status),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(15),
                                    bottomLeft: Radius.circular(15),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(children: [
                                    // Hora
                                    SizedBox(
                                      width: 46,
                                      child: Text(
                                        hora,
                                        style: TextStyle(
                                            color: PT.statusFg(status),
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(paciente,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: PT.text1,
                                                  fontSize: 14)),
                                          const SizedBox(height: 4),
                                          PT.statusChip(status),
                                          if (obs != null &&
                                              obs.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(obs,
                                                style: const TextStyle(
                                                    color: PT.text2,
                                                    fontSize: 12,
                                                    height: 1.4)),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ]),
                                ),
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mindflow_shared/mindflow_shared.dart';
import '../theme/paciente_theme.dart';
import '../services/consulta_monitor_service.dart';
import 'detalhe_consulta_screen.dart';

class MinhasConsultasScreen extends StatefulWidget {
  final bool isTab;
  const MinhasConsultasScreen({super.key, this.isTab = false});

  @override
  State<MinhasConsultasScreen> createState() => _MinhasConsultasScreenState();
}

class _MinhasConsultasScreenState extends State<MinhasConsultasScreen> {
  List<Map<String, dynamic>> _consultas = [];
  bool    _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    ConsultaMonitorService.adicionarListener(_onConsultasAtualizadas);
    // Uma única chamada: o monitor notifica via _onConsultasAtualizadas quando
    // terminar. _carregar() faz a requisição direta em paralelo para garantir
    // que o loading seja exibido imediatamente mesmo se o monitor demorar.
    _carregar();
  }

  @override
  void dispose() {
    ConsultaMonitorService.removerListener(_onConsultasAtualizadas);
    super.dispose();
  }

  void _onConsultasAtualizadas(List<Map<String, dynamic>> consultas) {
    if (!mounted) return;
    final lista = List<Map<String, dynamic>>.from(consultas)
      ..sort((a, b) {
        final da = DateTime.tryParse(a['dataHora'] ?? '') ?? DateTime(0);
        final db = DateTime.tryParse(b['dataHora'] ?? '') ?? DateTime(0);
        return db.compareTo(da);
      });
    for (final c in lista) {
      c['_dh'] = _fmt(c['dataHora'] as String?);
    }
    setState(() { _consultas = lista; _loading = false; });
  }

  Future<void> _carregar() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final res = await ApiClient.get('/consultas/minhas');
      if (res.statusCode == 200) {
        final lista = (jsonDecode(res.body) as List)
            .cast<Map<String, dynamic>>()
            ..sort((a, b) {
              final da = DateTime.tryParse(a['dataHora'] ?? '') ?? DateTime(0);
              final db = DateTime.tryParse(b['dataHora'] ?? '') ?? DateTime(0);
              return db.compareTo(da);
            });
        // Pré-computa a data formatada uma vez na carga, não em cada rebuild
        for (final c in lista) {
          c['_dh'] = _fmt(c['dataHora'] as String?);
        }
        setState(() { _consultas = lista; _loading = false; _erro = null; });
      } else {
        setState(() { _erro = 'Erro ao carregar consultas'; _loading = false; });
      }
    } catch (_) {
      setState(() { _erro = 'Verifique sua conexão'; _loading = false; });
    }
  }

  // Pré-computado em _carregar() e guardado em c['_dh'] — não é chamado no build
  static String _fmt(String? dh) {
    if (dh == null) return '';
    try {
      final dt = DateTime.parse(dh);
      const dias  = ['Dom','Seg','Ter','Qua','Qui','Sex','Sáb'];
      const meses = ['Jan','Fev','Mar','Abr','Mai','Jun',
                     'Jul','Ago','Set','Out','Nov','Dez'];
      return '${dias[dt.weekday % 7]}, ${dt.day} ${meses[dt.month - 1]} · '
             '${dt.hour.toString().padLeft(2,'0')}:'
             '${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return dh; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PcT.background,
      appBar: AppBar(
        title: const Text('Minhas Consultas'),
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
            color: PcT.text2,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: PcT.primary))
          : _erro != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                          color: PcT.errorLight,
                          borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.error_outline, color: PcT.error, size: 28),
                    ),
                    const SizedBox(height: 14),
                    Text(_erro!, style: const TextStyle(color: PcT.text2)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _carregar,
                        style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
                        child: const Text('Tentar novamente')),
                  ]),
                )
              : _consultas.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                              color: PcT.surfaceAlt,
                              borderRadius: BorderRadius.circular(20)),
                          child: const Icon(Icons.calendar_today_rounded,
                              color: PcT.text3, size: 28),
                        ),
                        const SizedBox(height: 14),
                        const Text('Você ainda não tem consultas',
                            style: TextStyle(color: PcT.text2)),
                      ]),
                    )
                  : RefreshIndicator(
                      onRefresh: _carregar,
                      color: PcT.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _consultas.length,
                        itemBuilder: (_, i) {
                          final c        = _consultas[i];
                          final id     = c['id']            as String;
                          final psi    = c['nomePsicologo'] as String? ?? '';
                          final dhFmt  = c['_dh']           as String? ?? '';
                          final status = c['status']        as String?;

                          return RepaintBoundary(
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DetalheConsultaScreen(consultaId: id),
                                ),
                              ).then((_) => _carregar()),
                              // Stack substitui IntrinsicHeight + Row(strip + content):
                              // a faixa colorida fica via Positioned.fill sem custo de
                              // layout em dois passos.
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: PcT.card,
                                clipBehavior: Clip.hardEdge,
                                child: Stack(children: [
                                  // Faixa lateral de status
                                  Positioned(
                                    left: 0, top: 0, bottom: 0,
                                    child: Container(
                                      width: 4,
                                      color: PcT.statusFg(status),
                                    ),
                                  ),
                                  // Conteúdo
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                                    child: Row(children: [
                                      Container(
                                        width: 40, height: 40,
                                        decoration: BoxDecoration(
                                          color: PcT.statusBg(status),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          PcT.statusIcon(status),
                                          color: PcT.statusFg(status),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(psi,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: PcT.text1,
                                                    fontSize: 14)),
                                            const SizedBox(height: 3),
                                            Text(dhFmt,
                                                style: const TextStyle(
                                                    color: PcT.text2,
                                                    fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          PcT.statusChip(status),
                                          const SizedBox(height: 6),
                                          const Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              color: PcT.text3,
                                              size: 12),
                                        ],
                                      ),
                                    ]),
                                  ),
                                ]),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

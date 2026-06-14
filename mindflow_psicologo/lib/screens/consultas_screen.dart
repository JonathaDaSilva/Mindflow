import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mindflow_shared/mindflow_shared.dart';
import '../theme/psicologo_theme.dart';

class ConsultasScreen extends StatefulWidget {
  final bool isTab;

  const ConsultasScreen({super.key, this.isTab = false});

  @override
  State<ConsultasScreen> createState() => _ConsultasScreenState();
}

class _ConsultasScreenState extends State<ConsultasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Map<String, dynamic>> _pendentes = [];
  List<Map<String, dynamic>> _todas     = [];
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
            ? (jsonDecode(r1.body) as List).cast<Map<String, dynamic>>()
            : [];
        _todas = r2.statusCode == 200
            ? (jsonDecode(r2.body) as List).cast<Map<String, dynamic>>()
            : [];
      });
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _atualizarStatus(String id, String status) async {
    try {
      final res = await ApiClient.patch(
          '/consultas/$id/status', {'status': status});
      if (res.statusCode == 200) {
        _carregar();
        if (!mounted) return;
        String msg;
        Color cor;
        switch (status) {
          case 'CONFIRMADA':
            msg = 'Consulta confirmada!';
            cor = PT.success;
          case 'CONCLUIDA':
            msg = 'Consulta marcada como realizada!';
            cor = PT.success;
          default:
            msg = 'Consulta recusada';
            cor = PT.error;
        }
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: cor));
      }
    } catch (_) {}
  }

  Future<void> _enviarLink(String id, String link) async {
    try {
      final res = await ApiClient.patch('/consultas/$id/link', {'link': link});
      if (res.statusCode == 200) {
        _carregar();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Link enviado ao paciente!'),
          backgroundColor: PT.success,
        ));
      }
    } catch (_) {}
  }

  Future<void> _cancelar(String id) async {
    final motivo = await _pedirMotivo();
    if (motivo == null || motivo.trim().isEmpty) return;

    try {
      final res = await ApiClient.patch(
          '/consultas/$id/cancelar', {'motivo': motivo});
      if (!mounted) return;
      if (res.statusCode == 200) {
        _carregar();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Consulta cancelada'),
          backgroundColor: PT.error,
        ));
      } else {
        final erro = jsonDecode(res.body)['error'] ?? 'Erro ao cancelar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(erro), backgroundColor: PT.error),
        );
      }
    } catch (_) {}
  }

  Future<String?> _pedirMotivo() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Motivo do cancelamento'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Informe o motivo...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            style:
                ElevatedButton.styleFrom(backgroundColor: PT.error),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  String _formatarDataHora(String? dh) {
    if (dh == null) return '';
    try {
      final dt = DateTime.parse(dh);
      const dias   = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
      const meses  = ['Jan','Fev','Mar','Abr','Mai','Jun',
                      'Jul','Ago','Set','Out','Nov','Dez'];
      return '${dias[dt.weekday % 7]}, ${dt.day} ${meses[dt.month - 1]} · '
             '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return dh;
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
      backgroundColor: PT.background,
      appBar: AppBar(
        title: const Text('Consultas'),
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
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: 'Pendentes (${_pendentes.length})'),
            Tab(text: 'Todas (${_todas.length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: PT.primary))
          : TabBarView(
              controller: _tabs,
              children: [
                _ListaConsultas(_pendentes,
                    mostrarAcoes: true,
                    onAtualizarStatus: _atualizarStatus,
                    onCancelar: _cancelar,
                    onEnviarLink: _enviarLink,
                    onRefresh: _carregar,
                    formatarDH: _formatarDataHora),
                _ListaConsultas(_todas,
                    mostrarAcoes: false,
                    onAtualizarStatus: _atualizarStatus,
                    onCancelar: _cancelar,
                    onEnviarLink: _enviarLink,
                    onRefresh: _carregar,
                    formatarDH: _formatarDataHora),
              ],
            ),
    );
  }
}

// ── Lista de consultas ────────────────────────────────────────────────────────

class _ListaConsultas extends StatelessWidget {
  final List<Map<String, dynamic>> lista;
  final bool mostrarAcoes;
  final Future<void> Function(String, String) onAtualizarStatus;
  final Future<void> Function(String) onCancelar;
  final Future<void> Function(String, String) onEnviarLink;
  final Future<void> Function() onRefresh;
  final String Function(String?) formatarDH;

  const _ListaConsultas(
    this.lista, {
    required this.mostrarAcoes,
    required this.onAtualizarStatus,
    required this.onCancelar,
    required this.onEnviarLink,
    required this.onRefresh,
    required this.formatarDH,
  });

  @override
  Widget build(BuildContext context) {
    if (lista.isEmpty) {
      return Center(
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
              child: Icon(
                mostrarAcoes
                    ? Icons.check_circle_outline_rounded
                    : Icons.event_note_rounded,
                color: PT.text3,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              mostrarAcoes
                  ? 'Nenhuma solicitação pendente'
                  : 'Nenhuma consulta encontrada',
              style: const TextStyle(color: PT.text2, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: PT.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: lista.length,
        itemBuilder: (_, i) {
          final c        = lista[i];
          final id       = c['id']          as String;
          final paciente = c['nomePaciente'] as String? ?? '';
          final dh       = c['dataHora']    as String?;
          final status   = c['status']      as String?;
          final obs      = c['observacao']  as String?;
          final link     = c['linkConsulta'] as String?;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: PT.card,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho: avatar + nome + status
                Row(children: [
                  _InicialAvatar(nome: paciente),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(paciente,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: PT.text1,
                                fontSize: 15)),
                        const SizedBox(height: 3),
                        Row(children: [
                          const Icon(Icons.schedule_rounded,
                              size: 12, color: PT.text3),
                          const SizedBox(width: 4),
                          Text(formatarDH(dh),
                              style: const TextStyle(
                                  color: PT.text2, fontSize: 12)),
                        ]),
                      ],
                    ),
                  ),
                  PT.statusChip(status),
                ]),

                // Observação
                if (obs != null && obs.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: PT.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.notes_rounded,
                          color: PT.text3, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(obs,
                            style: const TextStyle(
                                color: PT.text2,
                                fontSize: 13,
                                height: 1.4)),
                      ),
                    ]),
                  ),
                ],

                // Ações (pendentes)
                if (mostrarAcoes) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => onAtualizarStatus(id, 'RECUSADA'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: PT.error,
                          side: BorderSide(
                              color: PT.error.withOpacity(0.4), width: 1),
                          minimumSize: const Size(0, 40),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Recusar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            onAtualizarStatus(id, 'CONFIRMADA'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PT.success,
                          minimumSize: const Size(0, 40),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Confirmar'),
                      ),
                    ),
                  ]),
                ] else if (status == 'CONFIRMADA') ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _SecaoLinkConsulta(
                    id: id,
                    linkAtual: link,
                    onEnviarLink: onEnviarLink,
                    onCancelar: onCancelar,
                    onConcluir: onAtualizarStatus,
                  ),
                ] else if (status == 'CONCLUIDA' && link != null && link.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  _LinkChip(link: link),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Seção de link para consultas CONFIRMADA ──────────────────────────────────

class _SecaoLinkConsulta extends StatefulWidget {
  final String id;
  final String? linkAtual;
  final Future<void> Function(String, String) onEnviarLink;
  final Future<void> Function(String) onCancelar;
  final Future<void> Function(String, String) onConcluir;

  const _SecaoLinkConsulta({
    required this.id,
    required this.linkAtual,
    required this.onEnviarLink,
    required this.onCancelar,
    required this.onConcluir,
  });

  @override
  State<_SecaoLinkConsulta> createState() => _SecaoLinkConsultaState();
}

class _SecaoLinkConsultaState extends State<_SecaoLinkConsulta> {
  late final TextEditingController _ctrl;
  bool _salvandoLink = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.linkAtual ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de link
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Link da sessão (Meet, Zoom…)',
                  prefixIcon: const Icon(Icons.link_rounded),
                  suffixIcon: _salvandoLink
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2)))
                      : IconButton(
                          icon: const Icon(Icons.send_rounded, color: PT.primary),
                          tooltip: 'Enviar link',
                          onPressed: () async {
                            final link = _ctrl.text.trim();
                            if (link.isEmpty) return;
                            setState(() => _salvandoLink = true);
                            await widget.onEnviarLink(widget.id, link);
                            if (mounted) setState(() => _salvandoLink = false);
                          },
                        ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Botões: cancelar | marcar como realizada
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => widget.onCancelar(widget.id),
              style: OutlinedButton.styleFrom(
                foregroundColor: PT.error,
                side: BorderSide(color: PT.error.withOpacity(0.4), width: 1),
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Cancelar', style: TextStyle(fontSize: 13)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirmar = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Marcar como realizada'),
                    content: const Text(
                        'Confirma que esta sessão foi realizada?\n\n'
                        'O paciente poderá avaliar o atendimento.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Não')),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: PT.success),
                          child: const Text('Sim, confirmar')),
                    ],
                  ),
                );
                if (confirmar == true) {
                  widget.onConcluir(widget.id, 'CONCLUIDA');
                }
              },
              icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
              label: const Text('Realizada', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: PT.success,
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ]),
      ],
    );
  }
}

// Chip read-only exibindo o link quando status = CONCLUIDA
class _LinkChip extends StatelessWidget {
  final String link;
  const _LinkChip({required this.link});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: PT.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        const Icon(Icons.link_rounded, size: 14, color: PT.text3),
        const SizedBox(width: 8),
        Expanded(
          child: Text(link,
              style: const TextStyle(color: PT.text2, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}

class _InicialAvatar extends StatelessWidget {
  final String nome;
  const _InicialAvatar({required this.nome});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: PT.primaryLight,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          nome.isNotEmpty ? nome[0].toUpperCase() : '?',
          style: const TextStyle(
              color: PT.primary,
              fontWeight: FontWeight.w700,
              fontSize: 16),
        ),
      ),
    );
  }
}

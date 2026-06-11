import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mindflow_shared/mindflow_shared.dart';
import '../theme/paciente_theme.dart';

class DetalheConsultaScreen extends StatefulWidget {
  final String consultaId;
  const DetalheConsultaScreen({super.key, required this.consultaId});

  @override
  State<DetalheConsultaScreen> createState() => _DetalheConsultaScreenState();
}

class _DetalheConsultaScreenState extends State<DetalheConsultaScreen> {
  Map<String, dynamic>? _consulta;
  bool    _loading    = true;
  bool    _cancelando = false;
  String? _erro;

  // Avaliação pós-consulta (RF16)
  Map<String, dynamic>? _avaliacao;
  bool _carregandoAvaliacao = false;
  bool _enviandoAvaliacao   = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final res = await ApiClient.get('/consultas/${widget.consultaId}');
      if (res.statusCode == 200) {
        final consulta = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() => _consulta = consulta);
        if (consulta['status'] == 'CONCLUIDA') _carregarAvaliacao();
      } else {
        setState(() => _erro = 'Consulta não encontrada');
      }
    } catch (_) {
      setState(() => _erro = 'Erro de conexão');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _carregarAvaliacao() async {
    setState(() => _carregandoAvaliacao = true);
    try {
      final res = await ApiClient.get('/consultas/${widget.consultaId}/avaliacao');
      if (res.statusCode == 200) {
        setState(() => _avaliacao = jsonDecode(res.body) as Map<String, dynamic>);
      } else {
        setState(() => _avaliacao = null);
      }
    } catch (_) {
      // silencioso — a seção de avaliação simplesmente não aparece
    } finally {
      if (mounted) setState(() => _carregandoAvaliacao = false);
    }
  }

  Future<void> _abrirFormularioAvaliacao() async {
    int nota = 5;
    final comentarioCtrl = TextEditingController();

    final enviar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Avaliar atendimento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Como você avalia esta sessão?',
                  style: TextStyle(color: PcT.text2, fontSize: 13)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final valor = i + 1;
                  return IconButton(
                    onPressed: () => setDialogState(() => nota = valor),
                    icon: Icon(
                      valor <= nota ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: PcT.warning,
                      size: 30,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: comentarioCtrl,
                decoration: const InputDecoration(
                  labelText: 'Comentário (opcional)',
                  hintText: 'Conte como foi sua experiência...',
                ),
                maxLines: 3,
                maxLength: 500,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
              child: const Text('Enviar avaliação'),
            ),
          ],
        ),
      ),
    );

    if (enviar != true) return;

    setState(() => _enviandoAvaliacao = true);
    try {
      final res = await ApiClient.post(
        '/consultas/${widget.consultaId}/avaliacao',
        {'nota': nota, 'comentario': comentarioCtrl.text.trim()},
      );
      if (!mounted) return;
      if (res.statusCode == 201) {
        setState(() => _avaliacao = jsonDecode(res.body) as Map<String, dynamic>);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Obrigado pela sua avaliação!'),
          backgroundColor: PcT.success,
        ));
      } else {
        final erro = _extrairErroAvaliacao(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(erro), backgroundColor: PcT.error));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Erro de conexão'),
        backgroundColor: PcT.error,
      ));
    } finally {
      if (mounted) setState(() => _enviandoAvaliacao = false);
    }
  }

  String _extrairErroAvaliacao(String body) {
    try {
      final m = jsonDecode(body) as Map<String, dynamic>;
      return (m['error'] ?? m['message'] ?? 'Erro ao enviar avaliação').toString();
    } catch (_) {
      return 'Erro ao enviar avaliação';
    }
  }

  Future<void> _cancelar() async {
    final motivoCtrl = TextEditingController();
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar consulta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PcT.warningLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline_rounded,
                    color: PcT.warning, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Só é possível cancelar com mais de 24h de antecedência.',
                    style: TextStyle(
                        color: Color(0xFFD97706),
                        fontSize: 12,
                        height: 1.4),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: motivoCtrl,
              decoration: const InputDecoration(
                labelText: 'Motivo',
                hintText: 'Ex: Imprevisto pessoal',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, motivoCtrl.text.trim()),
            style: ElevatedButton.styleFrom(
                backgroundColor: PcT.error,
                minimumSize: const Size(0, 40)),
            child: const Text('Cancelar consulta'),
          ),
        ],
      ),
    );

    if (motivo == null || motivo.isEmpty) return;

    setState(() => _cancelando = true);
    try {
      final res = await ApiClient.patch(
          '/consultas/${widget.consultaId}/cancelar', {'motivo': motivo});
      if (!mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Consulta cancelada'),
          backgroundColor: PcT.error,
        ));
        Navigator.pop(context);
      } else {
        final erro = jsonDecode(res.body)['error'] ?? 'Erro ao cancelar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(erro), backgroundColor: PcT.error));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Erro de conexão'),
        backgroundColor: PcT.error,
      ));
    } finally {
      if (mounted) setState(() => _cancelando = false);
    }
  }

  bool _podeCancelar(String? status, String? dataHora) {
    if (status == 'CANCELADA' || status == 'RECUSADA' ||
        status == 'CONCLUIDA') return false;
    if (dataHora == null) return false;
    try {
      return DateTime.parse(dataHora)
          .difference(DateTime.now())
          .inHours >= 24;
    } catch (_) { return false; }
  }

  String _formatarDataHora(String? dh) {
    if (dh == null) return '';
    try {
      final dt = DateTime.parse(dh);
      const dias  = ['Domingo','Segunda-feira','Terça-feira','Quarta-feira',
                     'Quinta-feira','Sexta-feira','Sábado'];
      const meses = ['Janeiro','Fevereiro','Março','Abril','Maio','Junho',
                     'Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'];
      return '${dias[dt.weekday % 7]}, ${dt.day} de ${meses[dt.month - 1]} '
             'de ${dt.year} às ${dt.hour.toString().padLeft(2,'0')}:'
             '${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return dh; }
  }

  @override
  Widget build(BuildContext context) {
    final status = _consulta?['status']            as String?;
    final dh     = _consulta?['dataHora']          as String?;
    final psi    = _consulta?['nomePsicologo']      as String? ?? '';
    final obs    = _consulta?['observacao']         as String?;
    final motivo = _consulta?['motivoCancelamento'] as String?;
    final pagto  = _consulta?['formaPagamento']     as String?;
    final link   = _consulta?['linkConsulta']       as String?;

    return Scaffold(
      backgroundColor: PcT.background,
      appBar: AppBar(
        title: const Text('Detalhe da Consulta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: PcT.primary))
          : _erro != null
              ? Center(child: Text(_erro!,
                    style: const TextStyle(color: PcT.text2)))
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card de status (hero)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 24, horizontal: 20),
                          decoration: BoxDecoration(
                            color: PcT.statusBg(status),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: PcT.statusFg(status)
                                    .withOpacity(0.25),
                                width: 1),
                          ),
                          child: Column(children: [
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                color: PcT.statusFg(status)
                                    .withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                PcT.statusIcon(status),
                                color: PcT.statusFg(status),
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              PcT.statusLabel(status),
                              style: TextStyle(
                                  color: PcT.statusFg(status),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700),
                            ),
                          ]),
                        ),

                        const SizedBox(height: 16),

                        // Infos
                        _secao(Icons.person_outline_rounded, 'Psicólogo', psi),
                        _secao(Icons.calendar_today_rounded, 'Data e horário',
                            _formatarDataHora(dh)),
                        if (pagto != null)
                          _secao(Icons.payment_rounded, 'Forma de pagamento', pagto),
                        if (obs != null && obs.isNotEmpty)
                          _secao(Icons.notes_rounded, 'Observação', obs),
                        if (motivo != null && motivo.isNotEmpty)
                          _secao(Icons.info_outline_rounded,
                              'Motivo do cancelamento', motivo,
                              cor: PcT.error),

                        // Card de link da sessão
                        if (status == 'CONFIRMADA' || status == 'CONCLUIDA') ...[
                          const SizedBox(height: 4),
                          _cardLink(link, status),
                        ],

                        // Avaliação pós-consulta (RF16) — só para consultas concluídas
                        if (status == 'CONCLUIDA') ...[
                          const SizedBox(height: 4),
                          _secaoAvaliacao(),
                        ],

                        const SizedBox(height: 24),

                        // Botão cancelar
                        if (_podeCancelar(status, dh))
                          OutlinedButton.icon(
                            onPressed: _cancelando ? null : _cancelar,
                            icon: _cancelando
                                ? const SizedBox(
                                    width: 16, height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: PcT.error))
                                : const Icon(Icons.cancel_outlined,
                                    color: PcT.error),
                            label: Text(
                              _cancelando ? 'Cancelando...' : 'Cancelar consulta',
                              style: const TextStyle(color: PcT.error),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: PcT.error,
                              side: BorderSide(
                                  color: PcT.error.withOpacity(0.4),
                                  width: 1),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _secao(IconData icon, String titulo, String valor, {Color? cor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: PcT.card,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: cor != null
                  ? cor.withOpacity(0.1)
                  : PcT.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: cor ?? PcT.primary, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(color: PcT.text2, fontSize: 11)),
                const SizedBox(height: 3),
                Text(valor,
                    style: TextStyle(
                        color: cor ?? PcT.text1,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card de link da sessão: mostra o link enviado pelo psicólogo (com botão
  // copiar) ou uma mensagem de aguardo caso ainda não tenha sido enviado.
  Widget _cardLink(String? link, String? status) {
    final temLink = link != null && link.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: temLink ? PcT.successLight : PcT.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (temLink ? PcT.success : PcT.primary).withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(children: [
        Icon(
          temLink ? Icons.video_call_rounded : Icons.hourglass_top_rounded,
          color: temLink ? PcT.success : PcT.primary,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: temLink
              ? Text(
                  link!,
                  style: const TextStyle(
                      color: Color(0xFF065F46), fontSize: 13, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : const Text(
                  'Aguardando o psicólogo enviar o link da sessão.',
                  style: TextStyle(
                      color: PcT.primary, fontSize: 13, height: 1.4),
                ),
        ),
        if (temLink)
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 18),
            color: PcT.success,
            tooltip: 'Copiar link',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: link!));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Link copiado!'),
                duration: Duration(seconds: 2),
              ));
            },
          ),
      ]),
    );
  }

  // Seção de avaliação pós-consulta (RF16): mostra a avaliação já enviada
  // (somente leitura) ou um convite para avaliar, quando ainda não existe.
  Widget _secaoAvaliacao() {
    if (_carregandoAvaliacao) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: PcT.primary),
          ),
        ),
      );
    }

    if (_avaliacao != null) {
      final nota      = (_avaliacao!['nota'] as num?)?.toInt() ?? 0;
      final comentario = _avaliacao!['comentario'] as String?;
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: PcT.cardWith(accent: PcT.warning),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sua avaliação',
                style: TextStyle(color: PcT.text2, fontSize: 11)),
            const SizedBox(height: 6),
            Row(children: List.generate(5, (i) => Icon(
                  i < nota ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: PcT.warning, size: 20,
                ))),
            if (comentario != null && comentario.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(comentario,
                  style: const TextStyle(color: PcT.text1, fontSize: 14, height: 1.4)),
            ],
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: PcT.card,
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: PcT.warningLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.star_outline_rounded, color: PcT.warning, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'O psicólogo marcou a sessão como realizada. Confirme e avalie o atendimento.',
              style: TextStyle(color: PcT.text2, fontSize: 13, height: 1.4),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _enviandoAvaliacao ? null : _abrirFormularioAvaliacao,
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 38)),
            child: _enviandoAvaliacao
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Confirmar e avaliar'),
          ),
        ],
      ),
    );
  }
}

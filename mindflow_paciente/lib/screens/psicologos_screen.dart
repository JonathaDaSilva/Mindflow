import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mindflow_shared/mindflow_shared.dart';
import '../theme/paciente_theme.dart';
import 'slots_screen.dart';

class PsicologosScreen extends StatefulWidget {
  final bool isTab;

  /// Quando true, busca apenas psicólogos com aceitaEmergencia=true
  /// via GET /psicologos/emergencia
  final bool emergenciaOnly;

  const PsicologosScreen({
    super.key,
    this.isTab = false,
    this.emergenciaOnly = false,
  });

  @override
  State<PsicologosScreen> createState() => _PsicologosScreenState();
}

class _PsicologosScreenState extends State<PsicologosScreen> {
  List<Map<String, dynamic>> _todos     = [];
  List<Map<String, dynamic>> _filtrados = [];
  final _buscaCtrl = TextEditingController();
  bool    _loading = true;
  String? _erro;

  final Set<String> _carregandoSlot = {};

  String get _endpoint =>
      widget.emergenciaOnly ? '/psicologos/emergencia' : '/psicologos';

  @override
  void initState() {
    super.initState();
    _carregar();
    _buscaCtrl.addListener(_filtrar);
  }

  Future<void> _carregar() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final res = await ApiClient.get(_endpoint);
      if (res.statusCode == 200) {
        final lista = (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
        setState(() { _todos = lista; _filtrados = lista; });
      } else {
        setState(() => _erro = 'Erro ao carregar profissionais');
      }
    } catch (_) {
      setState(() => _erro = 'Verifique sua conexão');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _filtrar() {
    final q = _buscaCtrl.text.toLowerCase().trim();
    setState(() {
      _filtrados = q.isEmpty
          ? _todos
          : _todos.where((p) {
              final nome  = (p['nome']         ?? '').toString().toLowerCase();
              final espec = (p['especialidade'] ?? '').toString().toLowerCase();
              return nome.contains(q) || espec.contains(q);
            }).toList();
    });
  }

  Future<void> _verHorarios(Map<String, dynamic> psicologo) async {
    final id   = psicologo['id']   as String;
    final nome = psicologo['nome'] as String? ?? '';
    setState(() => _carregandoSlot.add(id));

    DateTime dataInicial = DateTime.now();
    try {
      final res = await ApiClient.get('/disponibilidades/$id/proximo-disponivel');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] as String;
        dataInicial = DateTime.parse(data);
      }
    } catch (_) {
    } finally {
      setState(() => _carregandoSlot.remove(id));
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SlotsScreen(
          psicologoId:   id,
          nomePsicologo: nome,
          dataInicial:   dataInicial,
        ),
      ),
    );
  }

  String _regimeLabel(String? r) {
    switch (r) {
      case 'PRESENCIAL': return 'Presencial';
      case 'REMOTO':     return 'Remoto';
      case 'HIBRIDO':    return 'Híbrido';
      default:           return r ?? '';
    }
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEmergencia = widget.emergenciaOnly;

    return Scaffold(
      backgroundColor: PcT.background,
      appBar: AppBar(
        title: Text(isEmergencia ? 'Atendimento de Emergência' : 'Psicólogos'),
        leading: widget.isTab
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pop(context),
              ),
        automaticallyImplyLeading: !widget.isTab && !isEmergencia,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _carregar,
            color: PcT.text2,
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner de emergência
          if (isEmergencia)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: PcT.emergencyLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: PcT.emergency.withOpacity(0.3), width: 1),
              ),
              child: Row(children: [
                const Icon(Icons.emergency_rounded,
                    color: PcT.emergency, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Estes profissionais aceitam atendimento '
                    'urgente remoto. Agende e entre em contato '
                    'diretamente.',
                    style: TextStyle(
                        color: PcT.emergency.withOpacity(0.9),
                        fontSize: 12,
                        height: 1.4),
                  ),
                ),
              ]),
            ),

          // Barra de busca
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _buscaCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou especialidade...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _buscaCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () { _buscaCtrl.clear(); _filtrar(); },
                      )
                    : null,
              ),
            ),
          ),

          // Contador
          if (!_loading && _erro == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_filtrados.length} profissional${_filtrados.length != 1 ? 'is' : ''} encontrado${_filtrados.length != 1 ? 's' : ''}',
                  style: const TextStyle(color: PcT.text2, fontSize: 12),
                ),
              ),
            ),

          // Lista
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: PcT.primary))
                : _erro != null
                    ? _ErroView(mensagem: _erro!, onRetry: _carregar)
                    : _filtrados.isEmpty
                        ? _VazioView(
                            isEmergencia: isEmergencia,
                            query: _buscaCtrl.text,
                          )
                        : RefreshIndicator(
                            onRefresh: _carregar,
                            color: PcT.primary,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _filtrados.length,
                              itemBuilder: (_, i) => _PsicologoCard(
                                psicologo:     _filtrados[i],
                                carregando:    _carregandoSlot.contains(_filtrados[i]['id']),
                                regimeLabel:   _regimeLabel,
                                onVerHorarios: () => _verHorarios(_filtrados[i]),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Card do psicólogo ─────────────────────────────────────────────────────────

class _PsicologoCard extends StatelessWidget {
  final Map<String, dynamic> psicologo;
  final bool carregando;
  final String Function(String?) regimeLabel;
  final VoidCallback onVerHorarios;

  const _PsicologoCard({
    required this.psicologo,
    required this.carregando,
    required this.regimeLabel,
    required this.onVerHorarios,
  });

  @override
  Widget build(BuildContext context) {
    final nome       = psicologo['nome']           as String? ?? '';
    final crp        = psicologo['crp']            as String? ?? '';
    final espec      = psicologo['especialidade']  as String? ?? '';
    final bio        = psicologo['bio']            as String? ?? '';
    final regime     = psicologo['regimeTrabalho'] as String?;
    final valor      = psicologo['valorSessao'];
    final duracao    = psicologo['duracaoSessaoMin'];
    final emergencia = psicologo['aceitaEmergencia'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: PcT.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: PcT.primaryLight,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: PcT.primary.withOpacity(0.2), width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: PcT.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(nome,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: PcT.text1)),
                        ),
                        if (emergencia)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: PcT.emergencyLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.emergency_rounded,
                                    color: PcT.emergency, size: 10),
                                SizedBox(width: 3),
                                Text('Emergência',
                                    style: TextStyle(
                                        color: PcT.emergency,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                      ]),
                      if (crp.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text('CRP: $crp',
                            style: const TextStyle(
                                color: PcT.text3, fontSize: 11)),
                      ],
                      if (espec.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: PcT.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(espec,
                              style: const TextStyle(
                                  color: PcT.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (bio.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(bio,
                  style: const TextStyle(
                      color: PcT.text2, fontSize: 13, height: 1.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),

          // Tags
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Wrap(spacing: 6, runSpacing: 6, children: [
              if (regime != null)
                _tag(regimeLabel(regime), PcT.text2, PcT.surfaceAlt),
              if (valor != null)
                _tag('R\$ $valor / sessão', PcT.accent, PcT.accentLight),
              if (duracao != null)
                _tag('$duracao min', PcT.text2, PcT.surfaceAlt),
            ]),
          ),

          const Divider(height: 1),

          // Botão agendar
          Padding(
            padding: const EdgeInsets.all(14),
            child: ElevatedButton.icon(
              onPressed: carregando ? null : onVerHorarios,
              icon: carregando
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.calendar_month_rounded, size: 18),
              label: Text(carregando
                  ? 'Buscando horários...'
                  : 'Ver horários disponíveis'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String texto, Color cor, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: PcT.border, width: 1),
    ),
    child: Text(texto,
        style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w500)),
  );
}

// ── Views auxiliares ──────────────────────────────────────────────────────────

class _ErroView extends StatelessWidget {
  final String mensagem;
  final VoidCallback onRetry;
  const _ErroView({required this.mensagem, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
              color: PcT.errorLight, borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.error_outline_rounded,
              color: PcT.error, size: 28),
        ),
        const SizedBox(height: 14),
        Text(mensagem,
            textAlign: TextAlign.center,
            style: const TextStyle(color: PcT.text2)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Tentar novamente'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
        ),
      ]),
    ),
  );
}

class _VazioView extends StatelessWidget {
  final bool isEmergencia;
  final String query;
  const _VazioView({required this.isEmergencia, required this.query});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
            color: PcT.surfaceAlt, borderRadius: BorderRadius.circular(20)),
        child: Icon(
          isEmergencia ? Icons.emergency_rounded : Icons.search_off_rounded,
          color: PcT.text3, size: 28,
        ),
      ),
      const SizedBox(height: 14),
      Text(
        isEmergencia
            ? 'Nenhum profissional\ndisponível para emergências'
            : query.isEmpty
                ? 'Nenhum psicólogo disponível'
                : 'Nenhum resultado para\n"$query"',
        textAlign: TextAlign.center,
        style: const TextStyle(color: PcT.text2, height: 1.5),
      ),
    ]),
  );
}

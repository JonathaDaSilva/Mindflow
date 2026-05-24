import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mindflow_shared/mindflow_shared.dart';
import 'slots_screen.dart';

class PsicologosScreen extends StatefulWidget {
  const PsicologosScreen({super.key});

  @override
  State<PsicologosScreen> createState() => _PsicologosScreenState();
}

class _PsicologosScreenState extends State<PsicologosScreen> {
  List<Map<String, dynamic>> _todos    = [];
  List<Map<String, dynamic>> _filtrados = [];
  final _buscaCtrl = TextEditingController();
  bool _loading = true;
  String? _erro;

  // Rastreia qual psicólogo está carregando o próximo dia
  final Set<String> _carregandoSlot = {};

  @override
  void initState() {
    super.initState();
    _carregar();
    _buscaCtrl.addListener(_filtrar);
  }

  Future<void> _carregar() async {
    try {
      final res = await ApiClient.get('/psicologos');
      if (res.statusCode == 200) {
        final lista = (jsonDecode(res.body) as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        setState(() {
          _todos     = lista;
          _filtrados = lista;
        });
      } else {
        setState(() => _erro = 'Erro ao carregar psicólogos');
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
              final nome  = (p['nome']          ?? '').toString().toLowerCase();
              final espec = (p['especialidade'] ?? '').toString().toLowerCase();
              return nome.contains(q) || espec.contains(q);
            }).toList();
    });
  }

  // Busca o próximo dia com slot livre e navega para a tela de slots
  Future<void> _verHorarios(Map<String, dynamic> psicologo) async {
    final id   = psicologo['id']   as String;
    final nome = psicologo['nome'] as String? ?? '';

    setState(() => _carregandoSlot.add(id));

    DateTime dataInicial = DateTime.now();

    try {
      final res = await ApiClient.get(
          '/disponibilidades/$id/proximo-disponivel');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] as String;
        dataInicial = DateTime.parse(data);
      }
    } catch (_) {
      // se falhar, usa hoje mesmo
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
      case 'PRESENCIAL': return '🏢 Presencial';
      case 'REMOTO':     return '💻 Remoto';
      case 'HIBRIDO':    return '🔀 Híbrido';
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Psicólogos',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Barra de pesquisa
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: TextField(
              controller: _buscaCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou especialidade...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppTheme.textSecond),
                suffixIcon: _buscaCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: AppTheme.textSecond),
                        onPressed: () {
                          _buscaCtrl.clear();
                          _filtrar();
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Contador
          if (!_loading && _erro == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_filtrados.length} profissional${_filtrados.length != 1 ? 'is' : ''} encontrado${_filtrados.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                      color: AppTheme.textSecond, fontSize: 13),
                ),
              ),
            ),

          // Lista
          Expanded(
            child: _loading
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
                              onPressed: () {
                                setState(() {
                                  _loading = true;
                                  _erro    = null;
                                });
                                _carregar();
                              },
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      )
                    : _filtrados.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.search_off_rounded,
                                    color: AppTheme.textSecond, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  _buscaCtrl.text.isEmpty
                                      ? 'Nenhum psicólogo disponível'
                                      : 'Nenhum resultado para\n"${_buscaCtrl.text}"',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: AppTheme.textSecond,
                                      height: 1.5),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            itemCount: _filtrados.length,
                            itemBuilder: (_, i) =>
                                _PsicologoCard(
                                  psicologo:      _filtrados[i],
                                  carregando:     _carregandoSlot
                                      .contains(_filtrados[i]['id']),
                                  regimeLabel:    _regimeLabel,
                                  onVerHorarios:  () =>
                                      _verHorarios(_filtrados[i]),
                                ),
                          ),
          ),
        ],
      ),
    );
  }
}

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
    final nome      = psicologo['nome']           as String? ?? '';
    final crp       = psicologo['crp']            as String? ?? '';
    final espec     = psicologo['especialidade']  as String? ?? '';
    final bio       = psicologo['bio']            as String? ?? '';
    final regime    = psicologo['regimeTrabalho'] as String?;
    final valor     = psicologo['valorSessao'];
    final duracao   = psicologo['duracaoSessaoMin'];
    final emergencia = psicologo['aceitaEmergencia'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.secondary),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nome,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary)),
                      if (crp.isNotEmpty)
                        Text('CRP: $crp',
                            style: const TextStyle(
                                color: AppTheme.textSecond, fontSize: 12)),
                      if (espec.isNotEmpty)
                        Text(espec,
                            style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (bio.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(bio,
                  style: const TextStyle(
                      color: AppTheme.textSecond,
                      fontSize: 13,
                      height: 1.5)),
            ),

          // Tags
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              if (regime != null)
                _tag(regimeLabel(regime), AppTheme.secondary),
              if (valor != null)
                _tag('R\$ $valor / sessão', AppTheme.primary),
              if (duracao != null)
                _tag('$duracao min', AppTheme.textSecond),
              if (emergencia)
                _tag('⚡ Emergências', AppTheme.error),
            ]),
          ),

          // Botão
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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

  Widget _tag(String texto, Color cor) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: cor.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(texto,
        style: TextStyle(
            color: cor, fontSize: 12, fontWeight: FontWeight.w500)),
  );
}
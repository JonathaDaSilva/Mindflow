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
  List<Map<String, dynamic>> _psicologos = [];
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final res = await ApiClient.get('/psicologos');
      if (res.statusCode == 200) {
        final lista = jsonDecode(res.body) as List;
        setState(() => _psicologos =
            lista.map((e) => e as Map<String, dynamic>).toList());
      } else {
        setState(() => _erro = 'Erro ao carregar psicólogos');
      }
    } catch (e) {
      setState(() => _erro = 'Verifique sua conexão');
    } finally {
      setState(() => _loading = false);
    }
  }

  String _regimeLabel(String? regime) {
    switch (regime) {
      case 'PRESENCIAL': return '🏢 Presencial';
      case 'REMOTO':     return '💻 Remoto';
      case 'HIBRIDO':    return '🔀 Híbrido';
      default:           return regime ?? '';
    }
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
        title: const Text('Psicólogos disponíveis',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
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
                            _erro = null;
                          });
                          _carregar();
                        },
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _psicologos.isEmpty
                  ? const Center(
                      child: Text('Nenhum psicólogo disponível',
                          style: TextStyle(color: AppTheme.textSecond)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: _psicologos.length,
                      itemBuilder: (_, i) {
                        final p = _psicologos[i];
                        final nome = p['nome'] as String? ?? '';
                        final crp  = p['crp']  as String? ?? '';
                        final espec = p['especialidade'] as String? ?? '';
                        final bio  = p['bio']  as String? ?? '';
                        final regime = p['regimeTrabalho'] as String?;
                        final valor = p['valorSessao'];
                        final duracao = p['duracaoSessaoMin'];
                        final emergencia =
                            p['aceitaEmergencia'] as bool? ?? false;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // Avatar
                                    Container(
                                      width: 56, height: 56,
                                      decoration: BoxDecoration(
                                        color: AppTheme.secondary
                                            .withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          nome.isNotEmpty
                                              ? nome[0].toUpperCase()
                                              : '?',
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(nome,
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      AppTheme.textPrimary)),
                                          if (crp.isNotEmpty)
                                            Text('CRP: $crp',
                                                style: const TextStyle(
                                                    color: AppTheme.textSecond,
                                                    fontSize: 12)),
                                          if (espec.isNotEmpty)
                                            Text(espec,
                                                style: const TextStyle(
                                                    color: AppTheme.primary,
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w500)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Bio
                              if (bio.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      20, 0, 20, 16),
                                  child: Text(bio,
                                      style: const TextStyle(
                                          color: AppTheme.textSecond,
                                          fontSize: 13,
                                          height: 1.5)),
                                ),

                              // Tags
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    20, 0, 20, 16),
                                child: Wrap(spacing: 8, runSpacing: 8,
                                  children: [
                                    if (regime != null)
                                      _tag(_regimeLabel(regime),
                                          AppTheme.secondary),
                                    if (valor != null)
                                      _tag('R\$ $valor / sessão',
                                          AppTheme.primary),
                                    if (duracao != null)
                                      _tag('$duracao min',
                                          AppTheme.textSecond),
                                    if (emergencia)
                                      _tag('⚡ Emergências',
                                          AppTheme.error),
                                  ],
                                ),
                              ),

                              // Botão ver horários
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 0, 16, 16),
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SlotsScreen(
                                        psicologoId: p['id'] as String,
                                        nomePsicologo: nome,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(
                                      Icons.calendar_month_rounded,
                                      size: 18),
                                  label: const Text('Ver horários disponíveis'),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _tag(String texto, Color cor) {
    return Container(
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
}
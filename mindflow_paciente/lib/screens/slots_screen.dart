import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mindflow_shared/mindflow_shared.dart';
import '../theme/paciente_theme.dart';

class SlotsScreen extends StatefulWidget {
  final String   psicologoId;
  final String   nomePsicologo;
  final DateTime dataInicial;

  const SlotsScreen({
    super.key,
    required this.psicologoId,
    required this.nomePsicologo,
    required this.dataInicial,
  });

  @override
  State<SlotsScreen> createState() => _SlotsScreenState();
}

class _SlotsScreenState extends State<SlotsScreen> {
  late DateTime _dataSelecionada;
  List<Map<String, dynamic>> _slots = [];
  bool    _loading = false;
  String? _erro;

  // Forma de pagamento preferida do paciente (RF03/RF13), usada ao agendar.
  // 'PIX' é apenas o fallback até que /pacientes/perfil responda.
  String _formaPagamentoPref = 'PIX';

  @override
  void initState() {
    super.initState();
    _dataSelecionada = widget.dataInicial;
    _buscarSlots(_dataSelecionada);
    _carregarFormaPagamentoPref();
  }

  Future<void> _carregarFormaPagamentoPref() async {
    try {
      final res = await ApiClient.get('/pacientes/perfil');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final pref = data['formaPagamentoPref'] as String?;
        if (pref != null && pref.isNotEmpty) {
          setState(() => _formaPagamentoPref = pref);
        }
      }
    } catch (_) {
      // mantém o fallback 'PIX' em caso de falha
    }
  }

  Future<void> _buscarSlots(DateTime data) async {
    setState(() { _loading = true; _erro = null; _slots = []; });
    try {
      final dataStr =
          '${data.year}-${data.month.toString().padLeft(2,'0')}-${data.day.toString().padLeft(2,'0')}';
      final res = await ApiClient.get(
          '/disponibilidades/${widget.psicologoId}/slots?data=$dataStr');
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          setState(() => _slots = decoded.cast<Map<String, dynamic>>());
        }
      } else if (res.statusCode == 204) {
        setState(() => _slots = []);
      } else {
        setState(() => _erro = 'Erro ${res.statusCode} ao buscar horários');
      }
    } catch (_) {
      setState(() => _erro = 'Verifique sua conexão');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() => _dataSelecionada = picked);
      _buscarSlots(picked);
    }
  }

  Future<void> _agendarConsulta(String dataHora, String horaFormatada) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar agendamento'),
        content: Text(
          'Psicólogo: ${widget.nomePsicologo}\n'
          'Data: ${_formatarData(_dataSelecionada)}\n'
          'Horário: $horaFormatada',
          style: const TextStyle(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(children: [
          SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          SizedBox(width: 12),
          Text('Agendando consulta...'),
        ]),
        duration: Duration(seconds: 15),
      ),
    );

    try {
      final res = await ApiClient.post('/consultas', {
        'psicologoId': widget.psicologoId,
        'dataHora':    dataHora,
        'formaPagamento': _formaPagamentoPref,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (res.statusCode == 201 || res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Consulta agendada com sucesso!'),
          backgroundColor: PcT.success,
          duration: Duration(seconds: 3),
        ));
        _buscarSlots(_dataSelecionada);
      } else if (res.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Horário já reservado. Escolha outro.'),
          backgroundColor: PcT.error,
        ));
        _buscarSlots(_dataSelecionada);
      } else {
        final erro = _extrairErro(res.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro: $erro'),
          backgroundColor: PcT.error,
        ));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Erro de conexão'),
        backgroundColor: PcT.error,
      ));
    }
  }

  String _extrairErro(String body) {
    try {
      final m = jsonDecode(body) as Map<String, dynamic>;
      return (m['error'] ?? m['message'] ?? 'Erro desconhecido').toString();
    } catch (_) {
      return body.isEmpty ? 'Erro desconhecido' : body;
    }
  }

  String _formatarData(DateTime d) {
    const dias  = ['Dom','Seg','Ter','Qua','Qui','Sex','Sáb'];
    const meses = ['Jan','Fev','Mar','Abr','Mai','Jun',
                   'Jul','Ago','Set','Out','Nov','Dez'];
    return '${dias[d.weekday % 7]}, ${d.day} de ${meses[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PcT.background,
      appBar: AppBar(
        title: Text(widget.nomePsicologo,
            style: const TextStyle(fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Seletor de data
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: _selecionarData,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: PcT.cardWith(accent: PcT.primary),
                  child: Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                          color: PcT.primaryLight,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.calendar_today_rounded,
                          color: PcT.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Data selecionada',
                              style: TextStyle(
                                  color: PcT.text2, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(_formatarData(_dataSelecionada),
                              style: const TextStyle(
                                  color: PcT.text1,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15)),
                        ],
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: PcT.text2),
                  ]),
                ),
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: PcT.primary))
                  : _erro != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 56, height: 56,
                                decoration: BoxDecoration(
                                    color: PcT.errorLight,
                                    borderRadius:
                                        BorderRadius.circular(16)),
                                child: const Icon(
                                    Icons.error_outline_rounded,
                                    color: PcT.error, size: 28),
                              ),
                              const SizedBox(height: 14),
                              Text(_erro!,
                                  style: const TextStyle(
                                      color: PcT.text2)),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  OutlinedButton(
                                    onPressed: _selecionarData,
                                    style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(0, 40)),
                                    child: const Text('Outra data'),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: () =>
                                        _buscarSlots(_dataSelecionada),
                                    style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(0, 40)),
                                    child: const Text('Tentar novamente'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : _slots.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 64, height: 64,
                                    decoration: BoxDecoration(
                                        color: PcT.surfaceAlt,
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: const Icon(
                                        Icons.event_busy_rounded,
                                        color: PcT.text3, size: 28),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'Sem horários disponíveis\nneste dia',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: PcT.text2, height: 1.5),
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: _selecionarData,
                                    child: const Text('Escolher outra data'),
                                  ),
                                ],
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 12),
                                    child: Text(
                                      '${_slots.length} horário${_slots.length > 1 ? 's' : ''} disponível${_slots.length > 1 ? 'is' : ''}',
                                      style: const TextStyle(
                                          color: PcT.text2,
                                          fontSize: 13),
                                    ),
                                  ),
                                  Expanded(
                                    child: GridView.builder(
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                        childAspectRatio: 2.0,
                                      ),
                                      itemCount: _slots.length,
                                      itemBuilder: (_, i) {
                                        final slot    = _slots[i];
                                        final hora    = slot['horaFormatada'] as String;
                                        final dataHora = slot['dataHora']    as String;
                                        return GestureDetector(
                                          onTap: () =>
                                              _agendarConsulta(dataHora, hora),
                                          child: Container(
                                            decoration: PcT.cardWith(
                                                accent: PcT.primary),
                                            child: Center(
                                              child: Text(hora,
                                                  style: const TextStyle(
                                                      color: PcT.primary,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 15)),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:mindflow_shared/mindflow_shared.dart';
import 'notificacao_local_service.dart';

class ConsultaMonitorService {
  static Timer? _timer;
  static int _ultimoTotal = -1; 
  static final List<void Function(int)> _listeners = [];

  /// Inicia o monitoramento. Verifica a cada 30 segundos.
  static void iniciar() {
    if (_timer != null) return; // já está rodando
    _verificar(); // verifica imediatamente
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _verificar(),
    );
  }

  static void parar() {
    _timer?.cancel();
    _timer = null;
    _ultimoTotal = -1;
  }

  /// Registra um listener para receber o total de pendentes
  static void adicionarListener(void Function(int) listener) {
    _listeners.add(listener);
  }

  static void removerListener(void Function(int) listener) {
    _listeners.remove(listener);
  }

  static Future<void> _verificar() async {
    try {
      final res = await ApiClient.get('/consultas/pendentes/count');
      if (res.statusCode != 200) return;

      final data   = jsonDecode(res.body) as Map<String, dynamic>;
      final total  = data['total'] as int? ?? 0;

      // Notifica listeners com o total atual
      for (final l in _listeners) {
        l(total);
      }

      // Se aumentou desde a última verificação, dispara notificação
      if (_ultimoTotal >= 0 && total > _ultimoTotal) {
        // Busca os novos pendentes para mostrar o nome
        final r2 = await ApiClient.get('/consultas/pendentes');
        if (r2.statusCode == 200) {
          final lista = (jsonDecode(r2.body) as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();
          if (lista.isNotEmpty) {
            final novo    = lista.first;
            final paciente = novo['nomePaciente'] as String? ?? 'Paciente';
            final dh       = novo['dataHora']     as String? ?? '';
            await NotificacaoLocalService
                .mostrarNovaSolicitacao(paciente, dh);
          }
        }
      }

      _ultimoTotal = total;
    } catch (_) {
      // Falha silenciosa — tenta na próxima rodada
    }
  }

  /// Força uma verificação imediata (ex: ao voltar para o app)
  static Future<void> verificarAgora() => _verificar();
}
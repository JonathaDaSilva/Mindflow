import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mindflow_shared/mindflow_shared.dart';
import 'notificacao_local_service.dart';

/// Monitora consultas pendentes do psicólogo.
///
/// Duas camadas:
///   1. SSE  → GET /notificacoes/stream  (tempo real via RabbitMQ → Spring → Flutter)
///   2. Poll → fallback a cada 30 s      (cobre app em background / SSE caído)
class ConsultaMonitorService {
  // ── SSE ──────────────────────────────────────────────────────────────────
  static StreamSubscription<String>? _sseSub;

  // ── Poll ──────────────────────────────────────────────────────────────────
  static Timer? _pollTimer;
  static int _ultimoTotal = -1;

  // Listeners da HomeScreen — recebem o total de pendentes
  static final List<void Function(int)> _listeners = [];

  // Reconexão SSE com backoff exponencial
  static Timer? _reconectTimer;
  static int _falhasSSE = 0;
  static const _maxFalhas = 5;

  // ─────────────────────────────────────────────────────────────────────────
  // API pública
  // ─────────────────────────────────────────────────────────────────────────

  static void iniciar() {
    if (!kIsWeb) _conectarSSE(); // SSE não funciona no browser via http package
    _iniciarPoll();
  }

  static void parar() {
    _sseSub?.cancel();        _sseSub = null;
    _pollTimer?.cancel();     _pollTimer = null;
    _reconectTimer?.cancel(); _reconectTimer = null;
    _ultimoTotal = -1;
    _falhasSSE = 0;
  }

  static void adicionarListener(void Function(int) listener) =>
      _listeners.add(listener);

  static void removerListener(void Function(int) listener) =>
      _listeners.remove(listener);

  static Future<void> verificarAgora() => _verificar();

  // ─────────────────────────────────────────────────────────────────────────
  // SSE
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> _conectarSSE() async {
    if (_falhasSSE >= _maxFalhas) return; // só o poll cuida

    try {
      await _sseSub?.cancel();

      final stream = await ApiClient.sseStream('/notificacoes/stream');

      _sseSub = stream.listen(
        _processarLinhaSSE,
        onError: (_) => _agendarReconexao(),
        onDone:  ()  => _agendarReconexao(),
        cancelOnError: false,
      );

      _falhasSSE = 0;
    } catch (_) {
      _agendarReconexao();
    }
  }

  static void _agendarReconexao() {
    _falhasSSE++;
    _sseSub?.cancel(); _sseSub = null;
    _reconectTimer?.cancel();

    if (_falhasSSE >= _maxFalhas) return;

    // Backoff: 5 s, 10 s, 20 s, 40 s, 80 s
    final delay = Duration(seconds: 5 * (1 << (_falhasSSE - 1)));
    _reconectTimer = Timer(delay, _conectarSSE);
  }

  /// Processa linhas SSE enviadas pelo backend.
  ///
  /// O Spring envia:
  ///   event: notificacao
  ///   data: {"consultaId":"...","status":"SOLICITADA","nomePaciente":"...","titulo":"...","corpo":"..."}
  static void _processarLinhaSSE(String linha) {
    if (linha.startsWith(':')) return; // comentário / heartbeat
    if (!linha.startsWith('data:')) return;

    final json = linha.substring(5).trim();
    if (json.isEmpty) return;

    try {
      final evento = jsonDecode(json) as Map<String, dynamic>;

      final titulo = evento['titulo'] as String?;
      final corpo  = evento['corpo']  as String?;

      if (titulo != null && corpo != null) {
        NotificacaoLocalService.mostrar(titulo, corpo);
      }

      // Atualiza contagem de pendentes em tempo real
      _verificar();
    } catch (_) {
      // JSON malformado — ignora
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Poll
  // ─────────────────────────────────────────────────────────────────────────

  static void _iniciarPoll() {
    if (_pollTimer != null) return;
    _verificar();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _verificar(),
    );
  }

  static Future<void> _verificar() async {
    try {
      final res = await ApiClient.get('/consultas/pendentes/count');
      if (res.statusCode != 200) return;

      final data  = jsonDecode(res.body) as Map<String, dynamic>;
      final total = data['total'] as int? ?? 0;

      for (final l in _listeners) l(total);

      // Se aumentou desde a última verificação e o SSE não notificou, dispara
      if (_ultimoTotal >= 0 && total > _ultimoTotal) {
        final r2 = await ApiClient.get('/consultas/pendentes');
        if (r2.statusCode == 200) {
          final lista = (jsonDecode(r2.body) as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();
          if (lista.isNotEmpty) {
            final novo     = lista.first;
            final paciente = novo['nomePaciente'] as String? ?? 'Paciente';
            final dh       = novo['dataHora']     as String? ?? '';
            await NotificacaoLocalService.mostrarNovaSolicitacao(paciente, dh);
          }
        }
      }

      _ultimoTotal = total;
    } catch (_) {
      // Falha silenciosa — tenta na próxima rodada
    }
  }
}

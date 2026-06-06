import 'dart:async';
import 'dart:convert';
import 'package:mindflow_shared/mindflow_shared.dart';
import 'notificacao_local_service.dart';

/// Monitora mudanças de status nas consultas do paciente.
///
/// Duas camadas:
///   1. SSE  → GET /notificacoes/stream  (tempo real via RabbitMQ → Spring → Flutter)
///   2. Poll → fallback a cada 30 s      (cobre app em background / SSE caído)
class ConsultaMonitorService {

  // ── SSE ──────────────────────────────────────────────────────────────────
  static StreamSubscription<String>? _sseSub;

  // ── Poll ──────────────────────────────────────────────────────────────────
  static Timer? _pollTimer;

  // Último status conhecido de cada consulta { id → status }
  static final Map<String, String> _ultimosStatus = {};

  // Listeners da HomeScreen
  static final List<void Function(List<Map<String, dynamic>>)> _listeners = [];

  // Reconexão SSE com backoff exponencial
  static Timer? _reconectTimer;
  static int    _falhasSSE  = 0;
  static const  _maxFalhas  = 5;

  // ─────────────────────────────────────────────────────────────────────────
  // API pública
  // ─────────────────────────────────────────────────────────────────────────

  static void iniciar() {
    _conectarSSE();
    _iniciarPoll();
  }

  static void parar() {
    _sseSub?.cancel();        _sseSub = null;
    _pollTimer?.cancel();     _pollTimer = null;
    _reconectTimer?.cancel(); _reconectTimer = null;
    _ultimosStatus.clear();
    _falhasSSE = 0;
  }

  static void adicionarListener(
      void Function(List<Map<String, dynamic>>) l) => _listeners.add(l);

  static void removerListener(
      void Function(List<Map<String, dynamic>>) l) => _listeners.remove(l);

  static Future<void> verificarAgora() => _poll();

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

      _falhasSSE = 0; // reconectou com sucesso
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

  /// Processa linhas SSE.
  ///
  /// O Spring envia:
  ///   event: notificacao
  ///   data: {"consultaId":"...","status":"CONFIRMADA","nomePsicologo":"...","dataHora":"...","titulo":"...","corpo":"..."}
  static void _processarLinhaSSE(String linha) {
    // Ignora comentários (ping / heartbeat)
    if (linha.startsWith(':')) return;
    if (!linha.startsWith('data:')) return;

    final json = linha.substring(5).trim();
    if (json.isEmpty) return;

    try {
      final evento = jsonDecode(json) as Map<String, dynamic>;

      final consultaId = evento['consultaId'] as String? ?? '';
      final status     = evento['status']     as String? ?? '';
      final nomePsi    = evento['nomePsicologo'] as String? ?? 'Psicólogo';
      final dataHora   = evento['dataHora']   as String? ?? '';
      final titulo     = evento['titulo']     as String?;
      final corpo      = evento['corpo']      as String?;

      if (consultaId.isEmpty || status.isEmpty) return;

      final anterior = _ultimosStatus[consultaId];
      if (anterior != status) {
        _ultimosStatus[consultaId] = status;

        // Usa título/corpo prontos do backend se disponíveis,
        // senão monta localmente
        if (titulo != null && corpo != null) {
          NotificacaoLocalService.mostrar(titulo, corpo);
        } else {
          _notificarPorStatus(status, nomePsi, dataHora);
        }

        // Atualiza a lista completa na UI
        _poll();
      }
    } catch (_) {
      // JSON malformado — ignora
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Poll
  // ─────────────────────────────────────────────────────────────────────────

  static void _iniciarPoll() {
    if (_pollTimer != null) return;
    _poll();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _poll());
  }

  static Future<void> _poll() async {
    try {
      final res = await ApiClient.get('/consultas/minhas');
      if (res.statusCode != 200) return;

      final lista = (jsonDecode(res.body) as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      for (final l in _listeners) l(lista);

      for (final c in lista) {
        final id     = c['id']            as String? ?? '';
        final status = c['status']        as String? ?? '';
        final psi    = c['nomePsicologo'] as String? ?? 'Psicólogo';
        final dh     = c['dataHora']      as String? ?? '';

        if (id.isEmpty) continue;

        final anterior = _ultimosStatus[id];
        if (anterior != null && anterior != status) {
          await _notificarPorStatus(status, psi, dh);
        }
        _ultimosStatus[id] = status;
      }
    } catch (_) {
      // Falha silenciosa
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Notificação local
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> _notificarPorStatus(
      String status, String nomePsicologo, String dataHora) async {
    final hora = _formatarHora(dataHora);
    switch (status) {
      case 'CONFIRMADA':
        await NotificacaoLocalService.mostrar(
          'Consulta confirmada! ✅',
          '$nomePsicologo confirmou sua consulta para $hora',
        );
        break;
      case 'RECUSADA':
        await NotificacaoLocalService.mostrar(
          'Consulta não disponível',
          '$nomePsicologo não pôde aceitar. Tente outro horário.',
        );
        break;
      case 'CANCELADA':
        await NotificacaoLocalService.mostrar(
          'Consulta cancelada',
          'Sua consulta com $nomePsicologo foi cancelada.',
        );
        break;
      case 'CONCLUIDA':
        await NotificacaoLocalService.mostrar(
          'Sessão concluída 🎉',
          'Sua sessão com $nomePsicologo foi concluída.',
        );
        break;
    }
  }

  static String _formatarHora(String dh) {
    try {
      final dt = DateTime.parse(dh);
      const meses = ['Jan','Fev','Mar','Abr','Mai','Jun',
                     'Jul','Ago','Set','Out','Nov','Dez'];
      return '${dt.day} ${meses[dt.month - 1]} às '
             '${dt.hour.toString().padLeft(2,'0')}:'
             '${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return dh; }
  }
}
package br.com.mindflow.services;

import br.com.mindflow.messaging.ConsultaEvent;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
public class NotificacaoSseService {

    private final Map<UUID, SseEmitter> emitters = new ConcurrentHashMap<>();
    private static final long TIMEOUT_MS = 10 * 60 * 1000L; // 10 min


    public SseEmitter registrar(UUID usuarioId) {
        SseEmitter antigo = emitters.remove(usuarioId);
        if (antigo != null) {
            try { antigo.complete(); } catch (Exception ignored) {}
        }

        SseEmitter emitter = new SseEmitter(TIMEOUT_MS);
        emitter.onCompletion(() -> emitters.remove(usuarioId));
        emitter.onTimeout(()    -> { emitters.remove(usuarioId); emitter.complete(); });
        emitter.onError(e       -> emitters.remove(usuarioId));

        emitters.put(usuarioId, emitter);
        log.info("[SSE] usuário {} conectado ({} ativos)", usuarioId, emitters.size());

        try {
            emitter.send(SseEmitter.event().comment("conectado"));
        } catch (IOException e) {
            emitters.remove(usuarioId);
        }

        return emitter;
    }

    // ── Chamado pelo ConsultaEventListener após cada notificacaoService.notificar() ──

    public void enviar(UUID usuarioId, String titulo, String corpo, ConsultaEvent event) {
        SseEmitter emitter = emitters.get(usuarioId);
        if (emitter == null) return; // usuário offline — poll de 30s cobre

        try {
            emitter.send(SseEmitter.event()
                .name("notificacao")
                .data(Map.of(
                    "consultaId",    event.consultaId().toString(),
                    "status",        event.status(),
                    "nomePsicologo", event.nomePsicologo(),
                    "nomePaciente",  event.nomePaciente(),
                    "dataHora",      event.dataHora(),
                    "titulo",        titulo,
                    "corpo",         corpo
                )));
            log.info("[SSE] → usuário {} | {}", usuarioId, event.status());
        } catch (IOException e) {
            emitters.remove(usuarioId);
        }
    }

    // ── Heartbeat (mantém conexão viva em proxies) ────────────────────────

    public void heartbeatTodos() {
        emitters.forEach((id, emitter) -> {
            try { emitter.send(SseEmitter.event().comment("ping")); }
            catch (IOException e) { emitters.remove(id); }
        });
    }

    public int totalConectados() { return emitters.size(); }
}
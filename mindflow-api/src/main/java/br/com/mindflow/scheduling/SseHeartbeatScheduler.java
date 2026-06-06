package br.com.mindflow.scheduling;
 
import br.com.mindflow.services.NotificacaoSseService;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
 
@Component
@RequiredArgsConstructor
public class SseHeartbeatScheduler {
 
    private final NotificacaoSseService sseService;
 
    @Scheduled(fixedDelay = 25_000)
    public void ping() {
        if (sseService.totalConectados() > 0) {
            sseService.heartbeatTodos();
        }
    }
}
 
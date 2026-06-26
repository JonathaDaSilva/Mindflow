package br.com.mindflow.scheduling;

import br.com.mindflow.services.LembreteService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

// RF15 — todos os dias às 8h, dispara lembretes de consulta para os
// pacientes e o resumo diário de agenda para os psicólogos.
@Slf4j
@Component
@RequiredArgsConstructor
public class LembreteScheduler {

    private final LembreteService lembreteService;

    @Scheduled(cron = "0 0 8 * * *")
    public void enviarLembretesDiarios() {
        log.info("[LembreteScheduler] disparando lembretes diários (08:00)");
        lembreteService.enviarLembretesDoDia();
    }
}

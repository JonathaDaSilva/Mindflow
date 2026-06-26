package br.com.mindflow.controllers;

import br.com.mindflow.services.LembreteService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

// RF15 — dispara manualmente o job de lembretes/resumo diário.
// O job roda automaticamente todo dia às 8h (ver LembreteScheduler), mas
// este endpoint existe para permitir demonstrar a funcionalidade a
// qualquer momento (ex.: em sala de aula), sem depender do horário do cron.
@RestController
@RequestMapping("/lembretes")
@RequiredArgsConstructor
public class LembreteController {

    private final LembreteService lembreteService;

    @PostMapping("/disparar")
    @PreAuthorize("hasRole('PSICOLOGO')")
    public ResponseEntity<Map<String, Integer>> disparar() {
        int total = lembreteService.enviarLembretesDoDia();
        return ResponseEntity.ok(Map.of("consultasNotificadas", total));
    }
}

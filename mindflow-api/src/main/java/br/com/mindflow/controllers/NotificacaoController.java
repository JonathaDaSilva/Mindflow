package br.com.mindflow.controllers;

import br.com.mindflow.entity.Usuario;
import br.com.mindflow.services.NotificacaoSseService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;
 
@RestController
@RequestMapping("/notificacoes")
@RequiredArgsConstructor
public class NotificacaoController {
 
    private final NotificacaoSseService sseService;
 
    /**
     * Flutter conecta aqui e fica escutando.
     * GET /api/notificacoes/stream
     */
    @GetMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter stream(@AuthenticationPrincipal Usuario usuario) {
        return sseService.registrar(usuario.getId());
    }
}
package br.com.mindflow.controllers;

import br.com.mindflow.dto.disponibilidade.BloqueioAgendaRequest;
import br.com.mindflow.dto.disponibilidade.BloqueioAgendaResponse;
import br.com.mindflow.entity.Usuario;
import br.com.mindflow.services.BloqueioAgendaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

// RF18 — psicólogo bloqueia/desbloqueia dias da agenda (ex.: férias).
@RestController
@RequestMapping("/disponibilidades/bloqueios")
@RequiredArgsConstructor
public class BloqueioAgendaController {

    private final BloqueioAgendaService bloqueioService;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public BloqueioAgendaResponse bloquear(@AuthenticationPrincipal Usuario usuario,
            @RequestBody @Valid BloqueioAgendaRequest req) {
        return bloqueioService.bloquear(usuario.getId(), req.data(), req.motivo());
    }

    @GetMapping
    public List<BloqueioAgendaResponse> listar(@AuthenticationPrincipal Usuario usuario) {
        return bloqueioService.listar(usuario.getId());
    }

    @DeleteMapping("/{data}")
    public void desbloquear(@AuthenticationPrincipal Usuario usuario,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate data) {
        bloqueioService.desbloquear(usuario.getId(), data);
    }
}

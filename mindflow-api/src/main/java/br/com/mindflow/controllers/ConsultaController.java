package br.com.mindflow.controllers;

import org.springframework.web.bind.annotation.*;
import org.springframework.http.HttpStatus;
import br.com.mindflow.dto.consulta.StatusUpdateRequest;
import java.util.*;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import br.com.mindflow.entity.Usuario;
import br.com.mindflow.dto.consulta.*;
import br.com.mindflow.services.ConsultaService;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/consultas")
@RequiredArgsConstructor
public class ConsultaController {

    private final ConsultaService consultaService;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ConsultaResponse solicitar(@AuthenticationPrincipal Usuario usuario, @RequestBody @Valid ConsultaRequest req) {
        return consultaService.solicitar(usuario.getId(), req);
    }

    @GetMapping("/minhas")
    public List<ConsultaResponse> minhasConsultas(@AuthenticationPrincipal Usuario usuario) {
        return consultaService.listarPorPaciente(usuario.getId());
    }

    @GetMapping("/pendentes")
    public List<ConsultaResponse> pendentes(@AuthenticationPrincipal Usuario usuario) {
        return consultaService.listarPendentes(usuario.getId());
    }

    // Psicólogo lista todas as suas consultas
    @GetMapping("/agenda")
    public List<ConsultaResponse> agenda(@AuthenticationPrincipal Usuario usuario) {
        return consultaService.listarPorPsicologo(usuario.getId());
    }

    @PatchMapping("/{id}/status")
    public ConsultaResponse atualizarStatus(@PathVariable UUID id, @RequestBody @Valid StatusUpdateRequest req) {
        return consultaService.atualizarStatus(id, req.status());
    }

    @PatchMapping("/{id}/cancelar")
    public ConsultaResponse cancelar(@PathVariable UUID id, @RequestBody @Valid CancelamentoRequest req) {
        return consultaService.cancelar(id, req.motivo());
    }
}
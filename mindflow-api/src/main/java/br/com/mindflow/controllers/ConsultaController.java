package br.com.mindflow.controllers;

import org.springframework.web.bind.annotation.*;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import br.com.mindflow.dto.consulta.StatusUpdateRequest;
import java.util.*;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import br.com.mindflow.entity.Usuario;
import br.com.mindflow.dto.consulta.*;
import br.com.mindflow.dto.avaliacao.AvaliacaoRequest;
import br.com.mindflow.dto.avaliacao.AvaliacaoResponse;
import br.com.mindflow.services.ConsultaService;
import br.com.mindflow.services.AvaliacaoService;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/consultas")
@RequiredArgsConstructor
public class ConsultaController {

    private final ConsultaService consultaService;
    private final AvaliacaoService avaliacaoService;

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ConsultaResponse solicitar(@AuthenticationPrincipal Usuario usuario,
            @RequestBody @Valid ConsultaRequest req) {
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

    @GetMapping("/{id}")
    public ConsultaResponse buscarPorId(@PathVariable UUID id) {
        return consultaService.buscarPorId(id);
    }

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

    @GetMapping("/pendentes/count")
    public ResponseEntity<Map<String, Integer>> contarPendentes(@AuthenticationPrincipal Usuario usuario) {
        int total = consultaService.listarPendentes(usuario.getId()).size();
        return ResponseEntity.ok(Map.of("total", total));
    }

    // RF16 — paciente avalia (nota 1-5 + comentário) a consulta já concluída
    @PostMapping("/{id}/avaliacao")
    @ResponseStatus(HttpStatus.CREATED)
    public AvaliacaoResponse avaliar(@AuthenticationPrincipal Usuario usuario,
            @PathVariable UUID id, @RequestBody @Valid AvaliacaoRequest req) {
        return avaliacaoService.avaliar(usuario.getId(), id, req);
    }

    // Consulta a avaliação de uma consulta (200 se existe, 204 se ainda não avaliada)
    @GetMapping("/{id}/avaliacao")
    public ResponseEntity<AvaliacaoResponse> buscarAvaliacao(@PathVariable UUID id) {
        var avaliacao = avaliacaoService.buscarPorConsulta(id);
        return avaliacao == null
                ? ResponseEntity.noContent().build()
                : ResponseEntity.ok(avaliacao);
    }
}
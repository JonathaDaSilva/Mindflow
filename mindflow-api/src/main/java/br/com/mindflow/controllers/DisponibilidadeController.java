package br.com.mindflow.controllers;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
import java.util.*;
import br.com.mindflow.entity.Usuario;
import br.com.mindflow.services.DisponibilidadeService;
import br.com.mindflow.dto.disponibilidade.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/disponibilidades")
@RequiredArgsConstructor
public class DisponibilidadeController {

    private final DisponibilidadeService disponibilidadeService;

    @PutMapping
    public List<DisponibilidadeResponse> salvar(@AuthenticationPrincipal Usuario usuario, @RequestBody @Valid DisponibilidadeListRequest body) {
        return disponibilidadeService.salvar(usuario.getId(), body.disponibilidades());
    }

    @GetMapping
    public List<DisponibilidadeResponse> minha(@AuthenticationPrincipal Usuario usuario) {
        return disponibilidadeService.listarPorPsicologo(usuario.getId());
    }

    @GetMapping("/{psicologoId}/slots")
    public List<SlotDisponivelResponse> slots(@PathVariable UUID psicologoId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate data) {
        return disponibilidadeService.buscarSlotsLivres(psicologoId, data);
    }

    @GetMapping("/{psicologoId}/proximo-disponivel")
    public ResponseEntity<Map<String, String>> proximoDisponivel(@PathVariable UUID psicologoId) {
    LocalDate data = disponibilidadeService.buscarProximoDiaDisponivel(psicologoId);

    if (data == null)
        return ResponseEntity.noContent().build();

    return ResponseEntity.ok(Map.of("data", data.toString()));
}
}
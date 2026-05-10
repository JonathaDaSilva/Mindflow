package br.com.mindflow.controllers;

import java.util.UUID;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import br.com.mindflow.dto.paciente.*;
import br.com.mindflow.services.PacienteService;
import br.com.mindflow.entity.Usuario;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/pacientes")
@RequiredArgsConstructor
public class PacienteController {

    private final PacienteService pacienteService;

    // Paciente lê seu próprio perfil (inclui observacoesSaude)
    @GetMapping("/perfil")
    public PacientePerfilResponse meuPerfil(@AuthenticationPrincipal Usuario usuario) {
        return pacienteService.buscarMeuPerfil(usuario.getId());
    }

    // Paciente atualiza seus dados
    @PutMapping("/perfil")
    public PacientePerfilResponse atualizar(@AuthenticationPrincipal Usuario usuario, @RequestBody @Valid PacientePerfilRequest req) {
        return pacienteService.atualizar(usuario.getId(), req);
    }

    // Psicólogo consulta perfil público do paciente (sem dados sensíveis)
    @GetMapping("/{usuarioId}")
    @PreAuthorize("hasRole('PSICOLOGO')")
    public PacientePerfilResponse perfilPublico(@PathVariable UUID usuarioId) {
        return pacienteService.buscarPerfilPublico(usuarioId);
    }
}

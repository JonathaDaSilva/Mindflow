package br.com.mindflow.controllers;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import br.com.mindflow.entity.Usuario;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import java.util.List;
import br.com.mindflow.dto.psicologo.*;
import br.com.mindflow.services.PsicologoService;
import java.util.UUID;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;

@RestController
@RequestMapping("/psicologos")
@RequiredArgsConstructor
public class PsicologoController {

    private final PsicologoService psicologoService;

    // GET /psicologos — paciente lista todos os psicólogos ativos
    @GetMapping
    public List<PsicologoPerfilResponse> listar() {
        return psicologoService.listarTodos();
    }

    // GET /psicologos/emergencia — paciente busca psicólogos que aceitam emergências
    @GetMapping("/emergencia")
    public List<PsicologoPerfilResponse> listarEmergencia() {
        return psicologoService.listarEmergencia();
    }

    // GET /psicologos/perfil — psicólogo lê seu próprio perfil
    @GetMapping("/perfil")
    public PsicologoPerfilResponse meuPerfil(@AuthenticationPrincipal Usuario usuario) {
        return psicologoService.buscarPorUsuario(usuario.getId());
    }

    // PUT /psicologos/perfil — psicólogo atualiza seu perfil
    @PutMapping("/perfil")
    public PsicologoPerfilResponse atualizar(@AuthenticationPrincipal Usuario usuario, @RequestBody @Valid PsicologoPerfilRequest req) {
        return psicologoService.atualizar(usuario.getId(), req);
    }

    @DeleteMapping("/delete/{usuarioId}")
    public void deletar(@PathVariable UUID usuarioId) {
        psicologoService.deletar(usuarioId);
    }
}
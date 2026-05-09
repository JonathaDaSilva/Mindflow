package br.com.mindflow.controllers;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import br.com.mindflow.entity.Usuario;
import br.com.mindflow.repositories.UsuarioRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import br.com.mindflow.dto.PsicologoPerfilRequest;
import br.com.mindflow.dto.PsicologoPerfilResponse;
import br.com.mindflow.services.PsicologoService;

@RestController
@RequestMapping("/psicologos")
@RequiredArgsConstructor
public class PsicologoController {

    private final PsicologoService psicologoService;

    // Paciente lista todos os psicólogos disponíveis
    @GetMapping
    public List<PsicologoPerfilResponse> listar() {
        return psicologoService.listarTodos();
    }

    // Psicólogo cria seu perfil após o cadastro
    @PostMapping("/perfil")
    @ResponseStatus(HttpStatus.CREATED)
    public PsicologoPerfilResponse criarPerfil(
            @AuthenticationPrincipal Usuario usuario,
            @RequestBody @Valid PsicologoPerfilRequest req) {
        return psicologoService.criarPerfil(usuario.getId(), req);
    }

    // Psicólogo busca/edita seu próprio perfil
    @GetMapping("/perfil")
    public PsicologoPerfilResponse meuPerfil(
            @AuthenticationPrincipal Usuario usuario) {
        return psicologoService.buscarPorUsuario(usuario.getId());
    }

    @PutMapping("/perfil")
    public PsicologoPerfilResponse atualizar(
            @AuthenticationPrincipal Usuario usuario,
            @RequestBody @Valid PsicologoPerfilRequest req) {
        return psicologoService.atualizar(usuario.getId(), req);
    }
}
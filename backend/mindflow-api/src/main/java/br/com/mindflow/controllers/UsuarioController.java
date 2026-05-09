package br.com.mindflow.controllers;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import br.com.mindflow.dto.usuario.*;
import br.com.mindflow.entity.Usuario;
import br.com.mindflow.repositories.UsuarioRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/usuarios")
@RequiredArgsConstructor
public class UsuarioController {

    private final UsuarioRepository usuarioRepo;

    // Retorna o usuário logado — @AuthenticationPrincipal
    // injeta o Usuario direto do token, sem query extra
    @GetMapping("/me")
    public UsuarioResponse me(
            @AuthenticationPrincipal Usuario usuario) {
        return UsuarioResponse.from(usuario);
    }

    @PutMapping("/me")
    public UsuarioResponse atualizar(
            @AuthenticationPrincipal Usuario usuario,
            @RequestBody @Valid AtualizarUsuarioRequest req) {
        usuario.setNome(req.nome());
        return UsuarioResponse.from(usuarioRepo.save(usuario));
    }
}

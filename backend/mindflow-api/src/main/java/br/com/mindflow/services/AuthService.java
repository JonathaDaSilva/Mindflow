package br.com.mindflow.services;

import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import br.com.mindflow.dto.auth.*;
import br.com.mindflow.entity.Usuario;
import br.com.mindflow.exceptions.EmailJaCadastradoException;
import br.com.mindflow.repositories.UsuarioRepository;
import br.com.mindflow.security.JwtService;
import lombok.RequiredArgsConstructor;

@Service @RequiredArgsConstructor
public class AuthService {

    private final UsuarioRepository   usuarioRepo;
    private final PasswordEncoder     passwordEncoder;
    private final JwtService           jwtService;
    private final AuthenticationManager authManager;

    public AuthResponse registrar(RegisterRequest req) {
        if (usuarioRepo.existsByEmail(req.email()))
            throw new EmailJaCadastradoException(req.email());

        var usuario = Usuario.builder()
            .nome(req.nome())
            .email(req.email())
            .senha(passwordEncoder.encode(req.senha())) // hash bcrypt
            .perfil(req.perfil())
            .build();

        usuarioRepo.save(usuario);
        String token = jwtService.gerarToken(usuario);

        return new AuthResponse(
            token, usuario.getNome(),
            usuario.getEmail(), usuario.getPerfil().name(),
            usuario.getId()
        );
    }

    public AuthResponse login(LoginRequest req) {
        // authenticate já verifica email + senha — lança exceção se errado
        authManager.authenticate(
            new UsernamePasswordAuthenticationToken(
                req.email(), req.senha())
        );
        var usuario = usuarioRepo.findByEmail(req.email()).orElseThrow();
        String token = jwtService.gerarToken(usuario);

        return new AuthResponse(
            token, usuario.getNome(),
            usuario.getEmail(), usuario.getPerfil().name(),
            usuario.getId()
        );
    }
}
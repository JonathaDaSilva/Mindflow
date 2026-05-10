package br.com.mindflow.services;

import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import br.com.mindflow.dto.auth.*;
import br.com.mindflow.entity.Usuario;
import br.com.mindflow.exceptions.DadosPerfilAusentesException;
import br.com.mindflow.exceptions.EmailJaCadastradoException;
import br.com.mindflow.repositories.PacientePerfilRepository;
import br.com.mindflow.repositories.PsicologoPerfilRepository;
import br.com.mindflow.repositories.UsuarioRepository;
import org.springframework.transaction.annotation.Transactional;
import br.com.mindflow.security.JwtService;
import lombok.RequiredArgsConstructor;
import br.com.mindflow.entity.Endereco;
import br.com.mindflow.entity.PacientePerfil;
import br.com.mindflow.entity.PsicologoPerfil;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UsuarioRepository usuarioRepo;
    private final PacientePerfilRepository pacienteRepo;
    private final PsicologoPerfilRepository psicologoRepo;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authManager;

    @Transactional
    public AuthResponse registrar(RegisterRequest req) {

        if (usuarioRepo.existsByEmail(req.email()))
            throw new EmailJaCadastradoException(req.email());

        var usuario = Usuario.builder()
                .nome(req.nome())
                .email(req.email())
                .senha(passwordEncoder.encode(req.senha()))
                .perfil(req.perfil())
                .build();

        usuarioRepo.save(usuario);

        switch (req.perfil()) {
            case ADMIN -> {}

            case PACIENTE -> {
                if (req.dadosPaciente() == null)
                    throw new DadosPerfilAusentesException("dadosPaciente");

                var d = req.dadosPaciente();
                pacienteRepo.save(
                        PacientePerfil.builder()
                                .usuario(usuario)
                                .telefone(d.telefone())
                                .dataNascimento(d.dataNascimento())
                                .formaPagamentoPref(d.formaPagamentoPref())
                                .observacoesSaude(d.observacoesSaude())
                                .build());
            }

            case PSICOLOGO -> {
                if (req.dadosPsicologo() == null)
                    throw new DadosPerfilAusentesException("dadosPsicologo");

                var d = req.dadosPsicologo();

                Endereco end = d.endereco() == null ? null
                        : Endereco.builder()
                                .logradouro(d.endereco().logradouro())
                                .numero(d.endereco().numero())
                                .bairro(d.endereco().bairro())
                                .cidade(d.endereco().cidade())
                                .estado(d.endereco().estado())
                                .cep(d.endereco().cep())
                                .build();

                psicologoRepo.save(
                        PsicologoPerfil.builder()
                                .usuario(usuario)
                                .crp(d.crp())
                                .especialidade(d.especialidade())
                                .bio(d.bio())
                                .regimeTrabalho(d.regimeTrabalho())
                                .duracaoSessaoMin(d.duracaoSessaoMin())
                                .valorSessao(d.valorSessao())
                                .aceitaEmergencia(
                                        Boolean.TRUE.equals(d.aceitaEmergencia()))
                                .endereco(end)
                                .build());
            }
        }

        return new AuthResponse(
                jwtService.gerarToken(usuario), 
                usuario.getId(), 
                usuario.getNome(), 
                usuario.getEmail(), 
                usuario.getPerfil().name() 
        );
    }

    public AuthResponse login(LoginRequest req) {
        authManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        req.email(), req.senha()));
        var usuario = usuarioRepo
                .findByEmail(req.email()).orElseThrow();

        return new AuthResponse(
                jwtService.gerarToken(usuario),
                usuario.getId(),
                usuario.getNome(),
                usuario.getEmail(),
                usuario.getPerfil().name());
    }
}
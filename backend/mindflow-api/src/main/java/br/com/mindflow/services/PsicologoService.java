package br.com.mindflow.services;

import br.com.mindflow.entity.Endereco;
import br.com.mindflow.entity.PsicologoPerfil;
import br.com.mindflow.entity.enums.PerfilUsuario;
import br.com.mindflow.exceptions.AcessoNegadoException;
import br.com.mindflow.exceptions.PerfilJaExisteException;
import br.com.mindflow.exceptions.PerfilNaoEncontradoException;
import br.com.mindflow.repositories.PsicologoPerfilRepository;
import br.com.mindflow.repositories.UsuarioRepository;
import jakarta.transaction.Transactional;
import br.com.mindflow.dto.psicologo.*;

import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service @RequiredArgsConstructor
public class PsicologoService {

    private final PsicologoPerfilRepository perfilRepo;
    private final UsuarioRepository         usuarioRepo;

    public PsicologoPerfilResponse criarPerfil(
            UUID usuarioId, PsicologoPerfilRequest req) {

        var usuario = usuarioRepo.findById(usuarioId).orElseThrow();

        if (usuario.getPerfil() != PerfilUsuario.PSICOLOGO)
            throw new AcessoNegadoException("Apenas psicólogos");

        if (perfilRepo.findByUsuarioId(usuarioId).isPresent())
            throw new PerfilJaExisteException();

        Endereco end = req.endereco() == null ? null :
            Endereco.builder()
                .logradouro(req.endereco().logradouro())
                .numero(req.endereco().numero())
                .bairro(req.endereco().bairro())
                .cidade(req.endereco().cidade())
                .estado(req.endereco().estado())
                .cep(req.endereco().cep())
                .build();

        var perfil = PsicologoPerfil.builder()
            .usuario(usuario)
            .crp(req.crp())
            .especialidade(req.especialidade())
            .bio(req.bio())
            .regimeTrabalho(req.regimeTrabalho())
            .duracaoSessaoMin(req.duracaoSessaoMin())
            .valorSessao(req.valorSessao())
            .aceitaEmergencia(
                Boolean.TRUE.equals(req.aceitaEmergencia()))
            .endereco(end)
            .build();

        return PsicologoPerfilResponse.from(perfilRepo.save(perfil));
    }

    public PsicologoPerfilResponse buscarPorUsuario(UUID usuarioId) {
        return perfilRepo.findByUsuarioId(usuarioId)
            .map(PsicologoPerfilResponse::from)
            .orElseThrow(PerfilNaoEncontradoException::new);
    }

    public List<PsicologoPerfilResponse> listarTodos() {
        return perfilRepo.findByAtivoTrue()
            .stream().map(PsicologoPerfilResponse::from).toList();
    }

    @Transactional
    public PsicologoPerfilResponse atualizar(
            UUID usuarioId, PsicologoPerfilRequest req) {

        var perfil = perfilRepo.findByUsuarioId(usuarioId)
            .orElseThrow(PerfilNaoEncontradoException::new);

        perfil.setCrp(req.crp());
        perfil.setEspecialidade(req.especialidade());
        perfil.setBio(req.bio());
        perfil.setRegimeTrabalho(req.regimeTrabalho());
        perfil.setDuracaoSessaoMin(req.duracaoSessaoMin());
        perfil.setValorSessao(req.valorSessao());
        perfil.setAceitaEmergencia(
            Boolean.TRUE.equals(req.aceitaEmergencia()));

        if (req.endereco() != null) {
            Endereco end = perfil.getEndereco() != null
                ? perfil.getEndereco()
                : new Endereco();
            end.setLogradouro(req.endereco().logradouro());
            end.setNumero(req.endereco().numero());
            end.setBairro(req.endereco().bairro());
            end.setCidade(req.endereco().cidade());
            end.setEstado(req.endereco().estado());
            end.setCep(req.endereco().cep());
            perfil.setEndereco(end);
        }
        return PsicologoPerfilResponse.from(perfilRepo.save(perfil));
    }
}

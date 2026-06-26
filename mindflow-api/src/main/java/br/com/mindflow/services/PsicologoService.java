package br.com.mindflow.services;

import br.com.mindflow.entity.Endereco;
import br.com.mindflow.entity.enums.RegimeTrabalho;
import br.com.mindflow.exceptions.PerfilNaoEncontradoException;
import br.com.mindflow.repositories.PsicologoPerfilRepository;
import br.com.mindflow.repositories.UsuarioRepository;
import jakarta.transaction.Transactional;
import br.com.mindflow.dto.psicologo.*;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class PsicologoService {

    private final PsicologoPerfilRepository perfilRepo;
    private final UsuarioRepository usuarioRepository;
    // Paciente lista todos os psicólogos ativos
    public List<PsicologoPerfilResponse> listarTodos() {
        return perfilRepo.findByAtivoTrue()
            .stream()
            .map(PsicologoPerfilResponse::from)
            .toList();
    }

    // RF05 — paciente busca psicólogos com filtro opcional por
    // especialidade (contains, case-insensitive), regime de trabalho
    // e preço máximo da sessão. Parâmetros nulos são ignorados (sem
    // filtro nesse campo).
    public List<PsicologoPerfilResponse> buscar(
            String especialidade, RegimeTrabalho regimeTrabalho, BigDecimal precoMax) {

        String termo = especialidade == null ? null : especialidade.trim().toLowerCase();

        return perfilRepo.findByAtivoTrue()
            .stream()
            .filter(p -> termo == null || termo.isBlank()
                || (p.getEspecialidade() != null
                    && p.getEspecialidade().toLowerCase().contains(termo)))
            .filter(p -> regimeTrabalho == null || regimeTrabalho == p.getRegimeTrabalho())
            .filter(p -> precoMax == null
                || (p.getValorSessao() != null && p.getValorSessao().compareTo(precoMax) <= 0))
            .map(PsicologoPerfilResponse::from)
            .toList();
    }

    // Paciente lista apenas psicólogos que aceitam atendimentos de emergência
    public List<PsicologoPerfilResponse> listarEmergencia() {
        return perfilRepo.findByAtivoTrueAndAceitaEmergenciaTrue()
            .stream()
            .map(PsicologoPerfilResponse::from)
            .toList();
    }

    // Psicólogo lê seu próprio perfil
    public PsicologoPerfilResponse buscarPorUsuario(UUID usuarioId) {
        return perfilRepo.findByUsuarioId(usuarioId)
            .map(PsicologoPerfilResponse::from)
            .orElseThrow(PerfilNaoEncontradoException::new);
    }

    // Psicólogo atualiza seu perfil
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
                ? perfil.getEndereco() : new Endereco();
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

    @Transactional
    public void deletar(UUID usuarioId) {
        var perfil = perfilRepo.findByUsuarioId(usuarioId)
            .orElseThrow(PerfilNaoEncontradoException::new);
        perfilRepo.delete(perfil);
        usuarioRepository.deleteById(usuarioId);
    }
}

package br.com.mindflow.services;

import br.com.mindflow.dto.paciente.PacientePerfilRequest;
import br.com.mindflow.dto.paciente.PacientePerfilResponse;
import br.com.mindflow.exceptions.PerfilNaoEncontradoException;
import br.com.mindflow.repositories.PacientePerfilRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PacienteService {

    private final PacientePerfilRepository pacienteRepo;

    // Paciente lê seu próprio perfil (com observacoesSaude)
    public PacientePerfilResponse buscarMeuPerfil(UUID usuarioId) {
        return pacienteRepo.findByUsuarioId(usuarioId)
            .map(PacientePerfilResponse::from)
            .orElseThrow(PerfilNaoEncontradoException::new);
    }

    // Psicólogo consulta perfil de um paciente (sem dados sensíveis)
    public PacientePerfilResponse buscarPerfilPublico(UUID usuarioId) {
        return pacienteRepo.findByUsuarioId(usuarioId)
            .map(PacientePerfilResponse::fromPublico)
            .orElseThrow(PerfilNaoEncontradoException::new);
    }

    // Paciente atualiza seus dados
    @Transactional
    public PacientePerfilResponse atualizar(
            UUID usuarioId, PacientePerfilRequest req) {

        var perfil = pacienteRepo.findByUsuarioId(usuarioId)
            .orElseThrow(PerfilNaoEncontradoException::new);

        perfil.setTelefone(req.telefone());
        perfil.setDataNascimento(req.dataNascimento());
        perfil.setFormaPagamentoPref(req.formaPagamentoPref());
        perfil.setObservacoesSaude(req.observacoesSaude());

        return PacientePerfilResponse.from(pacienteRepo.save(perfil));
    }

    @Transactional
    public void deletar(UUID usuarioId) {
        var perfil = pacienteRepo.findByUsuarioId(usuarioId)
            .orElseThrow(PerfilNaoEncontradoException::new);
        pacienteRepo.delete(perfil);
    }
}
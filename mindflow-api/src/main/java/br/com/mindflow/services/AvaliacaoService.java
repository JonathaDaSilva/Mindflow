package br.com.mindflow.services;

import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import br.com.mindflow.dto.avaliacao.AvaliacaoRequest;
import br.com.mindflow.dto.avaliacao.AvaliacaoResponse;
import br.com.mindflow.entity.Avaliacao;
import br.com.mindflow.entity.enums.StatusConsulta;
import br.com.mindflow.exceptions.AcessoNegadoException;
import br.com.mindflow.exceptions.AvaliacaoJaExisteException;
import br.com.mindflow.exceptions.ConsultaNaoConcluidaException;
import br.com.mindflow.exceptions.ConsultaNaoEncontradaException;
import br.com.mindflow.repositories.AvaliacaoRepository;
import br.com.mindflow.repositories.ConsultaRepository;
import lombok.RequiredArgsConstructor;

// RF16 — Permitir que o paciente atribua uma nota (1 a 5) e um comentário
// para o psicólogo após a consulta concluída.
@Service
@RequiredArgsConstructor
public class AvaliacaoService {

    private final AvaliacaoRepository avaliacaoRepo;
    private final ConsultaRepository consultaRepo;

    @Transactional
    public AvaliacaoResponse avaliar(UUID pacienteId, UUID consultaId, AvaliacaoRequest req) {

        var consulta = consultaRepo.findById(consultaId)
                .orElseThrow(ConsultaNaoEncontradaException::new);

        // só o paciente dono da consulta pode avaliá-la
        if (!consulta.getPaciente().getId().equals(pacienteId))
            throw new AcessoNegadoException("Você não pode avaliar esta consulta");

        // só consultas concluídas podem ser avaliadas
        if (consulta.getStatus() != StatusConsulta.CONCLUIDA)
            throw new ConsultaNaoConcluidaException();

        // uma avaliação por consulta
        if (avaliacaoRepo.existsByConsultaId(consultaId))
            throw new AvaliacaoJaExisteException();

        var avaliacao = Avaliacao.builder()
                .consulta(consulta)
                .nota(req.nota())
                .comentario(req.comentario())
                .build();

        return AvaliacaoResponse.from(avaliacaoRepo.save(avaliacao));
    }

    public AvaliacaoResponse buscarPorConsulta(UUID consultaId) {
        return avaliacaoRepo.findByConsultaId(consultaId)
                .map(AvaliacaoResponse::from)
                .orElse(null);
    }

    // Psicólogo consulta as avaliações que recebeu
    public List<AvaliacaoResponse> listarPorPsicologo(UUID psicologoId) {
        return avaliacaoRepo.findByConsulta_PsicologoIdOrderByCriadoEmDesc(psicologoId)
                .stream().map(AvaliacaoResponse::from).toList();
    }
}

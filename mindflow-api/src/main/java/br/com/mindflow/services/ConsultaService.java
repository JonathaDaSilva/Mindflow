package br.com.mindflow.services;

import java.time.*;
import java.time.temporal.ChronoUnit;
import java.util.*;
import org.springframework.transaction.annotation.Transactional;
import br.com.mindflow.entity.enums.StatusConsulta;
import br.com.mindflow.dto.consulta.*;
import br.com.mindflow.entity.Consulta;
import br.com.mindflow.exceptions.CancelamentoForaPrazoException;
import br.com.mindflow.exceptions.ConsultaNaoEncontradaException;
import br.com.mindflow.exceptions.HorarioIndisponivelException;
import br.com.mindflow.repositories.ConsultaRepository;
import br.com.mindflow.repositories.UsuarioRepository;
import org.springframework.stereotype.Service;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class ConsultaService {

    private final ConsultaRepository consultaRepo;
    private final UsuarioRepository usuarioRepo;
    private final DisponibilidadeService disponibilidadeService;

    @Transactional
    public ConsultaResponse solicitar(UUID pacienteId, ConsultaRequest req) {

        if (consultaRepo.existeConflito(req.psicologoId(), req.dataHora()))
            throw new HorarioIndisponivelException();
        
        var slotsLivres = disponibilidadeService.buscarSlotsLivres(
                req.psicologoId(), req.dataHora().toLocalDate());

        boolean slotValido = slotsLivres.stream()
                .anyMatch(s -> s.dataHora().equals(req.dataHora()));

        if (!slotValido)
            throw new HorarioIndisponivelException();

        var paciente = usuarioRepo.findById(pacienteId).orElseThrow();
        var psicologo = usuarioRepo.findById(req.psicologoId()).orElseThrow();

        var consulta = Consulta.builder()
                .paciente(paciente)
                .psicologo(psicologo)
                .dataHora(req.dataHora())
                .status(StatusConsulta.SOLICITADA)
                .formaPagamento(req.formaPagamento())
                .observacao(req.observacao())
                .build();

        return ConsultaResponse.from(consultaRepo.save(consulta));
    }

    // Paciente lista suas consultas
    public List<ConsultaResponse> listarPorPaciente(UUID pacienteId) {
        return consultaRepo.findByPacienteId(pacienteId)
                .stream().map(ConsultaResponse::from).toList();
    }

    // Psicólogo lista consultas pendentes (solicitadas)
    public List<ConsultaResponse> listarPendentes(UUID psicologoId) {
        return consultaRepo.findByPsicologoIdAndStatus(
                psicologoId, StatusConsulta.SOLICITADA)
                .stream().map(ConsultaResponse::from).toList();
    }

    // Psicólogo lista todas as suas consultas
    public List<ConsultaResponse> listarPorPsicologo(UUID psicologoId) {
        return consultaRepo.findByPsicologoId(psicologoId)
                .stream().map(ConsultaResponse::from).toList();
    }

    // Psicólogo confirma ou recusa consulta
    @Transactional
    public ConsultaResponse atualizarStatus(
            UUID consultaId, StatusConsulta novoStatus) {

        var consulta = consultaRepo.findById(consultaId)
                .orElseThrow(ConsultaNaoEncontradaException::new);

        consulta.setStatus(novoStatus);
        return ConsultaResponse.from(consultaRepo.save(consulta));
    }

    // Cancelamento com regra das 24h — qualquer lado
    @Transactional
    public ConsultaResponse cancelar(
            UUID consultaId, String motivo) {

        var consulta = consultaRepo.findById(consultaId)
                .orElseThrow(ConsultaNaoEncontradaException::new);

        // regra: não pode cancelar com menos de 24h de antecedência
        long horasRestantes = ChronoUnit.HOURS.between(
                LocalDateTime.now(), consulta.getDataHora());

        if (horasRestantes < 24)
            throw new CancelamentoForaPrazoException(horasRestantes);

        consulta.setStatus(StatusConsulta.CANCELADA);
        consulta.setMotivoCancelamento(motivo);
        return ConsultaResponse.from(consultaRepo.save(consulta));
    }
}
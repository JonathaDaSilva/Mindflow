package br.com.mindflow.services;

import br.com.mindflow.dto.disponibilidade.BloqueioAgendaResponse;
import br.com.mindflow.entity.BloqueioAgenda;
import br.com.mindflow.exceptions.BloqueioNaoEncontradoException;
import br.com.mindflow.exceptions.DataJaBloqueadaException;
import br.com.mindflow.repositories.BloqueioAgendaRepository;
import br.com.mindflow.repositories.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

// RF18 — psicólogo bloqueia dias da agenda (ex.: férias, feriado).
// Datas bloqueadas são excluídas do cálculo de slots livres em
// DisponibilidadeService.buscarSlotsLivres(), sem afetar consultas já
// confirmadas para aquele dia (o bloqueio só impede novos agendamentos).
@Service
@RequiredArgsConstructor
public class BloqueioAgendaService {

    private final BloqueioAgendaRepository bloqueioRepo;
    private final UsuarioRepository usuarioRepo;

    @Transactional
    public BloqueioAgendaResponse bloquear(UUID psicologoId, LocalDate data, String motivo) {
        if (bloqueioRepo.existsByPsicologoIdAndData(psicologoId, data))
            throw new DataJaBloqueadaException();

        var psicologo = usuarioRepo.findById(psicologoId)
                .orElseThrow(() -> new RuntimeException("Psicólogo não encontrado"));

        var bloqueio = BloqueioAgenda.builder()
                .psicologo(psicologo)
                .data(data)
                .motivo(motivo)
                .build();

        return BloqueioAgendaResponse.from(bloqueioRepo.save(bloqueio));
    }

    public List<BloqueioAgendaResponse> listar(UUID psicologoId) {
        return bloqueioRepo.findByPsicologoIdOrderByDataAsc(psicologoId)
                .stream()
                .map(BloqueioAgendaResponse::from)
                .toList();
    }

    @Transactional
    public void desbloquear(UUID psicologoId, LocalDate data) {
        if (!bloqueioRepo.existsByPsicologoIdAndData(psicologoId, data))
            throw new BloqueioNaoEncontradoException();
        bloqueioRepo.deleteByPsicologoIdAndData(psicologoId, data);
    }

    public boolean estaBloqueado(UUID psicologoId, LocalDate data) {
        return bloqueioRepo.existsByPsicologoIdAndData(psicologoId, data);
    }
}

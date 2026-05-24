package br.com.mindflow.services;

import br.com.mindflow.dto.disponibilidade.DisponibilidadeRequest;
import br.com.mindflow.dto.disponibilidade.DisponibilidadeResponse;
import br.com.mindflow.dto.disponibilidade.*;
import br.com.mindflow.entity.Disponibilidade;
import br.com.mindflow.repositories.ConsultaRepository;
import br.com.mindflow.repositories.DisponibilidadeRepository;
import br.com.mindflow.repositories.PsicologoPerfilRepository;
import br.com.mindflow.repositories.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.stream.Collectors;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class DisponibilidadeService {

        private final DisponibilidadeRepository disponibilidadeRepo;
        private final ConsultaRepository consultaRepo;
        private final PsicologoPerfilRepository psicologoPerfilRepo;
        private final UsuarioRepository usuarioRepo;

        @Transactional
        public List<DisponibilidadeResponse> salvar(
                        UUID psicologoId,
                        List<DisponibilidadeRequest> requests) {

                var psicologo = usuarioRepo.findById(psicologoId)
                                .orElseThrow(() -> new RuntimeException("Psicólogo não encontrado"));

                disponibilidadeRepo.deleteByPsicologoId(psicologoId);

                var novas = requests.stream()
                                .map(r -> Disponibilidade.builder()
                                                .psicologo(psicologo)
                                                .diaSemana(r.diaSemana())
                                                .horaInicio(r.horaInicio())
                                                .horaFim(r.horaFim())
                                                .build())
                                .toList();

                return disponibilidadeRepo.saveAll(novas)
                                .stream()
                                .map(DisponibilidadeResponse::from)
                                .toList();
        }

        public List<DisponibilidadeResponse> listarPorPsicologo(UUID psicologoId) {
                return disponibilidadeRepo.findByPsicologoId(psicologoId)
                                .stream()
                                .map(DisponibilidadeResponse::from)
                                .toList();
        }

        public List<SlotDisponivelResponse> buscarSlotsLivres(
                        UUID psicologoId, LocalDate data) {

                int diaSemana = data.getDayOfWeek().getValue();

                var disponibilidades = disponibilidadeRepo
                                .findByPsicologoId(psicologoId).stream()
                                .filter(d -> d.getDiaSemana() == diaSemana)
                                .toList();

                if (disponibilidades.isEmpty())
                        return List.of();

                int duracaoMin = psicologoPerfilRepo
                                .findByUsuarioId(psicologoId)
                                .map(p -> p.getDuracaoSessaoMin() != null
                                                ? p.getDuracaoSessaoMin()
                                                : 50)
                                .orElse(50);

                List<SlotDisponivelResponse> slots = new ArrayList<>();
                List<Disponibilidade> disponibilidadesList = new ArrayList<>(disponibilidades);

                for (var disp : disponibilidadesList) {
                        LocalTime hora = disp.getHoraInicio();

                        while (!hora.plusMinutes(duracaoMin).isAfter(disp.getHoraFim())) {
                                LocalDateTime dataHora = LocalDateTime.of(data, hora);

                                if (!consultaRepo.existeConflito(psicologoId, dataHora)) {
                                        slots.add(new SlotDisponivelResponse(
                                                        dataHora,
                                                        hora.format(DateTimeFormatter.ofPattern("HH:mm"))));
                                }
                                hora = hora.plusMinutes(duracaoMin);
                        }
                }

                return slots;
        }

        public LocalDate buscarProximoDiaDisponivel(UUID psicologoId) {
                var disponibilidades = disponibilidadeRepo.findByPsicologoId(psicologoId);

                if (disponibilidades.isEmpty())
                        return null;

                var diasComDisp = disponibilidades.stream()
                                .map(Disponibilidade::getDiaSemana)
                                .collect(Collectors.toSet());

                LocalDate hoje = LocalDate.now();
                for (int i = 0; i < 60; i++) {
                        LocalDate data = hoje.plusDays(i);
                        int diaSemana = data.getDayOfWeek().getValue();
                        if (diasComDisp.contains(diaSemana)) {
                                var slots = buscarSlotsLivres(psicologoId, data);
                                if (!slots.isEmpty())
                                        return data;
                        }
                }
                return null;
        }
}

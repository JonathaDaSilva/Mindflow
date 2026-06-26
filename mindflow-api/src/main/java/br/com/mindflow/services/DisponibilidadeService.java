package br.com.mindflow.services;

import br.com.mindflow.dto.disponibilidade.DisponibilidadeRequest;
import br.com.mindflow.dto.disponibilidade.DisponibilidadeResponse;
import br.com.mindflow.dto.disponibilidade.*;
import br.com.mindflow.entity.Disponibilidade;
import br.com.mindflow.repositories.BloqueioAgendaRepository;
import br.com.mindflow.repositories.ConsultaRepository;
import br.com.mindflow.repositories.DisponibilidadeRepository;
import br.com.mindflow.repositories.PsicologoPerfilRepository;
import br.com.mindflow.repositories.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
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

@Slf4j
@Service
@RequiredArgsConstructor
public class DisponibilidadeService {

    private final DisponibilidadeRepository disponibilidadeRepo;
    private final ConsultaRepository consultaRepo;
    private final PsicologoPerfilRepository psicologoPerfilRepo;
    private final UsuarioRepository usuarioRepo;
    private final BloqueioAgendaRepository bloqueioAgendaRepo;

    // ── Salvar / Listar ───────────────────────────────────────────────────────

    @Transactional
    public List<DisponibilidadeResponse> salvar(UUID psicologoId,
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

    // ── Buscar slots livres ───────────────────────────────────────────────────

    public List<SlotDisponivelResponse> buscarSlotsLivres(UUID psicologoId, LocalDate data) {

        /*
         * ATENÇÃO — convenção do diaSemana:
         *
         * java.time.DayOfWeek.getValue() → 1=SEG … 7=DOM  (ISO-8601)
         *
         * Se o front / app do psicólogo salvou usando outra convenção
         * (ex.: 0=DOM … 6=SÁB, igual ao JS Date.getDay()), os valores
         * nunca vão bater e a lista sempre ficará vazia.
         *
         * Aqui usamos ISO-8601 (1-7). Certifique-se de que o app do
         * psicólogo envia os mesmos valores ao chamar PUT /disponibilidades.
         */
        int diaSemana = data.getDayOfWeek().getValue(); // 1=SEG … 7=DOM

        log.debug("[Slots] psicologoId={} data={} diaSemana(ISO)={}", psicologoId, data, diaSemana);

        // RF18 — dia bloqueado pelo psicólogo (ex.: férias) nunca tem slots livres
        if (bloqueioAgendaRepo.existsByPsicologoIdAndData(psicologoId, data)) {
            log.debug("[Slots] data {} bloqueada pelo psicólogo — retornando vazio", data);
            return List.of();
        }

        var todasDisp = disponibilidadeRepo.findByPsicologoId(psicologoId);
        log.debug("[Slots] total de disponibilidades cadastradas: {}", todasDisp.size());
        todasDisp.forEach(d ->
                log.debug("  → diaSemana={} {}–{}", d.getDiaSemana(), d.getHoraInicio(), d.getHoraFim()));

        var disponibilidades = todasDisp.stream()
                .filter(d -> d.getDiaSemana() == diaSemana)
                .toList();

        log.debug("[Slots] disponibilidades para o dia {}: {}", diaSemana, disponibilidades.size());

        if (disponibilidades.isEmpty()) {
            return List.of();
        }

        int duracaoMin = psicologoPerfilRepo
                .findByUsuarioId(psicologoId)
                .map(p -> p.getDuracaoSessaoMin() != null ? p.getDuracaoSessaoMin() : 50)
                .orElse(50);

        log.debug("[Slots] duração da sessão: {} min", duracaoMin);

        List<SlotDisponivelResponse> slots = new ArrayList<>();

        for (var disp : disponibilidades) {
            LocalTime hora = disp.getHoraInicio();

            while (!hora.plusMinutes(duracaoMin).isAfter(disp.getHoraFim())) {
                LocalDateTime dataHora = LocalDateTime.of(data, hora);
                boolean temConflito = consultaRepo.existeConflito(psicologoId, dataHora);

                log.debug("[Slots]   slot {} conflito={}", dataHora, temConflito);

                if (!temConflito) {
                    slots.add(new SlotDisponivelResponse(
                            dataHora,
                            hora.format(DateTimeFormatter.ofPattern("HH:mm"))));
                }
                hora = hora.plusMinutes(duracaoMin);
            }
        }

        log.debug("[Slots] slots livres encontrados: {}", slots.size());
        return slots;
    }

    // ── Próximo dia disponível ────────────────────────────────────────────────

    public LocalDate buscarProximoDiaDisponivel(UUID psicologoId) {
        var disponibilidades = disponibilidadeRepo.findByPsicologoId(psicologoId);

        if (disponibilidades.isEmpty()) {
            log.debug("[ProximoDia] psicólogo {} sem disponibilidades cadastradas", psicologoId);
            return null;
        }

        var diasComDisp = disponibilidades.stream()
                .map(Disponibilidade::getDiaSemana)
                .collect(Collectors.toSet());

        log.debug("[ProximoDia] dias com disponibilidade (ISO 1-7): {}", diasComDisp);

        LocalDate hoje = LocalDate.now();
        for (int i = 0; i < 60; i++) {
            LocalDate data = hoje.plusDays(i);
            int diaSemana = data.getDayOfWeek().getValue();
            if (diasComDisp.contains(diaSemana)) {
                var slotsLivres = buscarSlotsLivres(psicologoId, data);
                if (!slotsLivres.isEmpty()) {
                    log.debug("[ProximoDia] primeiro dia com slots: {}", data);
                    return data;
                }
            }
        }

        log.debug("[ProximoDia] nenhum dia disponível nos próximos 60 dias");
        return null;
    }
}
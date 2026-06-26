package br.com.mindflow.services;

import br.com.mindflow.entity.Consulta;
import br.com.mindflow.entity.enums.StatusConsulta;
import br.com.mindflow.repositories.ConsultaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

// RF15 — lembretes automáticos de consultas do dia (para o paciente) e
// resumo diário de agenda (para o psicólogo). A lógica fica isolada nesta
// classe para poder ser chamada tanto pelo job agendado (LembreteScheduler,
// roda todo dia às 8h) quanto por um disparo manual via endpoint — útil
// para demonstração em sala, sem precisar esperar o horário do cron.
@Slf4j
@Service
@RequiredArgsConstructor
public class LembreteService {

    private final ConsultaRepository consultaRepo;
    private final NotificacaoService notificacaoService;

    private static final DateTimeFormatter HORA_FMT = DateTimeFormatter.ofPattern("HH:mm");

    public int enviarLembretesDoDia() {
        LocalDate hoje = LocalDate.now();
        var inicio = hoje.atStartOfDay();
        var fim = hoje.atTime(LocalTime.MAX);

        List<Consulta> consultasHoje =
                consultaRepo.findByDataHoraBetweenAndStatus(inicio, fim, StatusConsulta.CONFIRMADA);

        log.info("[Lembrete] {} consulta(s) confirmada(s) para hoje ({})",
                consultasHoje.size(), hoje);

        // 1) lembrete individual para cada paciente
        for (var consulta : consultasHoje) {
            String hora = consulta.getDataHora().toLocalTime().format(HORA_FMT);
            notificacaoService.notificar(
                    consulta.getPaciente().getId(),
                    "Lembrete de consulta hoje",
                    "Você tem consulta hoje às " + hora + " com "
                            + consulta.getPsicologo().getNome() + ".");
        }

        // 2) resumo diário para cada psicólogo com consulta(s) no dia
        Map<java.util.UUID, List<Consulta>> porPsicologo = consultasHoje.stream()
                .collect(Collectors.groupingBy(c -> c.getPsicologo().getId()));

        porPsicologo.forEach((psicologoId, lista) -> {
            var primeira = lista.get(0).getPsicologo();
            notificacaoService.notificar(
                    psicologoId,
                    "Resumo do seu dia",
                    "Você tem " + lista.size() + " consulta(s) agendada(s) hoje.");
            log.info("[Lembrete] resumo enviado a {} ({} consulta(s))",
                    primeira.getNome(), lista.size());
        });

        return consultasHoje.size();
    }
}

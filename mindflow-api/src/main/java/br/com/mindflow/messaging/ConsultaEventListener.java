package br.com.mindflow.messaging;

import br.com.mindflow.services.NotificacaoService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.core.Message;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

import tools.jackson.databind.ObjectMapper;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@Slf4j
@Component
@RequiredArgsConstructor
public class ConsultaEventListener {

    private final ObjectMapper objectMapper;
    private final NotificacaoService notificacaoService;

    @RabbitListener(queues = Eventos.CONSULTA_SOLICITADA)
    public void onConsultaSolicitada(Message message) {
        try {
            var event = objectMapper.readValue(
                    message.getBody(), ConsultaEvent.class);

            log.info("[{}] Nova consulta | paciente: {} | psicólogo: {} | data: {}",
                    Eventos.CONSULTA_SOLICITADA,
                    event.nomePaciente(),
                    event.nomePsicologo(),
                    event.dataHora());

            // Notifica o PSICÓLOGO
            notificacaoService.notificar(
                    event.psicologoId(),
                    "Nova solicitação de consulta",
                    String.format("%s solicitou uma consulta para %s",
                            event.nomePaciente(),
                            formatarData(event.dataHora())));

        } catch (Exception e) {
            log.error("[{}] Erro ao processar: {}",
                    Eventos.CONSULTA_SOLICITADA, e.getMessage());
        }
    }

    @RabbitListener(queues = Eventos.CONSULTA_CONFIRMADA)
    public void onConsultaConfirmada(Message message) {
        try {
            var event = objectMapper.readValue(
                    message.getBody(), ConsultaEvent.class);

            log.info("[{}] Consulta confirmada | paciente: {} | data: {}",
                    Eventos.CONSULTA_CONFIRMADA,
                    event.nomePaciente(),
                    event.dataHora());

            // Notifica o PACIENTE
            notificacaoService.notificar(
                    event.pacienteId(),
                    "Consulta confirmada! ✅",
                    String.format("Sua consulta com %s foi confirmada para %s",
                            event.nomePsicologo(),
                            formatarData(event.dataHora())));

        } catch (Exception e) {
            log.error("[{}] Erro: {}", Eventos.CONSULTA_CONFIRMADA, e.getMessage());
        }
    }

    @RabbitListener(queues = Eventos.CONSULTA_RECUSADA)
    public void onConsultaRecusada(Message message) {
        try {
            var event = objectMapper.readValue(
                    message.getBody(), ConsultaEvent.class);

            log.info("[{}] Consulta recusada | paciente: {}",
                    Eventos.CONSULTA_RECUSADA,
                    event.nomePaciente());

            // Notifica o PACIENTE
            notificacaoService.notificar(
                    event.pacienteId(),
                    "Consulta não disponível",
                    String.format("%s não pôde aceitar sua solicitação para %s. Tente outro horário.",
                            event.nomePsicologo(),
                            formatarData(event.dataHora())));

        } catch (Exception e) {
            log.error("[{}] Erro: {}", Eventos.CONSULTA_RECUSADA, e.getMessage());
        }
    }

    @RabbitListener(queues = Eventos.CONSULTA_CANCELADA)
    public void onConsultaCancelada(Message message) {
        try {
            var event = objectMapper.readValue(
                    message.getBody(), ConsultaEvent.class);

            log.info("[{}] Consulta cancelada | consultaId: {}",
                    Eventos.CONSULTA_CANCELADA,
                    event.consultaId());

            // Notifica AMBOS os lados
            notificacaoService.notificar(
                    event.pacienteId(),
                    "Consulta cancelada",
                    String.format("Sua consulta de %s foi cancelada", formatarData(event.dataHora())));

            notificacaoService.notificar(
                    event.psicologoId(),
                    "Consulta cancelada",
                    String.format("A consulta com %s em %s foi cancelada",
                            event.nomePaciente(),
                            formatarData(event.dataHora())));

        } catch (Exception e) {
            log.error("[{}] Erro: {}", Eventos.CONSULTA_CANCELADA, e.getMessage());
        }
    }

    private String formatarData(String dataHora) {
        try {
            var dt = LocalDateTime.parse(dataHora);
            return dt.format(DateTimeFormatter.ofPattern("dd/MM/yyyy 'às' HH:mm"));
        } catch (Exception e) {
            return dataHora;
        }
    }
}
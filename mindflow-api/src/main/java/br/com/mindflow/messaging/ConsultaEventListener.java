package br.com.mindflow.messaging;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.core.Message;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

import tools.jackson.databind.ObjectMapper;

@Slf4j
@Component
@RequiredArgsConstructor
public class ConsultaEventListener {

    private final ObjectMapper objectMapper;

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
        } catch (Exception e) {
            log.error("[{}] Erro ao processar evento: {}",
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
        } catch (Exception e) {
            log.error("[{}] Erro: {}", Eventos.CONSULTA_CANCELADA, e.getMessage());
        }
    }
}
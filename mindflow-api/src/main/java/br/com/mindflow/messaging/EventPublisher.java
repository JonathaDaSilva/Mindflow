package br.com.mindflow.messaging;

import br.com.mindflow.entity.Consulta;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.core.Message;
import org.springframework.amqp.core.MessageBuilder;
import org.springframework.amqp.core.MessageProperties;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Component;

import tools.jackson.databind.ObjectMapper;

import java.time.LocalDateTime;

@Slf4j
@Component
@RequiredArgsConstructor
public class EventPublisher {

    private final RabbitTemplate rabbitTemplate;
    private final ObjectMapper objectMapper;

    public void publicar(String routingKey, Consulta consulta) {
        try {
            var event = new ConsultaEvent(
                    consulta.getId(),
                    consulta.getPaciente().getId(),
                    consulta.getPsicologo().getId(),
                    consulta.getPaciente().getNome(),
                    consulta.getPsicologo().getNome(),
                    consulta.getStatus().name(),
                    consulta.getDataHora().toString(),
                    LocalDateTime.now().toString()
            );

            byte[] payload = objectMapper.writeValueAsBytes(event);

            Message message = MessageBuilder
                    .withBody(payload)
                    .andProperties(MessageBuilder
                            .withBody(payload)
                            .build()
                            .getMessageProperties())
                    .setContentType(MessageProperties.CONTENT_TYPE_JSON)
                    .build();

            rabbitTemplate.send(RabbitMQConfig.EXCHANGE, routingKey, message);

            log.info("[MOM] Evento publicado: {} | consultaId: {}",
                    routingKey, consulta.getId());

        } catch (Exception e) {
            log.error("[MOM] Erro ao publicar evento {}: {}", routingKey, e.getMessage());
        }
    }
}
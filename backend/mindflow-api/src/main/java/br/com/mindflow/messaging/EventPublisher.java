package br.com.mindflow.messaging;

import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Component;

@Component
public class EventPublisher {

    private final RabbitTemplate rabbitTemplate;

    public EventPublisher(RabbitTemplate rabbitTemplate) {
        this.rabbitTemplate = rabbitTemplate;
    }

    public void publishConsultaEvent(Object eventData) {
        rabbitTemplate.convertAndSend(
            RabbitMQConfig.CONSULTA_EXCHANGE,
            RabbitMQConfig.NOTIFICACAO_ROUTING_KEY,
            eventData
        );
    }
}

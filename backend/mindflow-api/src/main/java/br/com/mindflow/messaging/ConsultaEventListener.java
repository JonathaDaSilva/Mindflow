package br.com.mindflow.messaging;

import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

@Component
public class ConsultaEventListener {

    @RabbitListener(queues = RabbitMQConfig.NOTIFICACAO_QUEUE)
    public void onConsultaStatusChange(Object event) {
        System.out.println("Processando notificação assíncrona: " + event.toString());
        
        // integrar com Firebase (Push) ou serviços de e-mail. Pensando ainda.
    }
}

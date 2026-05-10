package br.com.mindflow.messaging;

import org.springframework.amqp.core.*;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitMQConfig {

    public static final String CONSULTA_EXCHANGE = "consulta.exchange";
    public static final String NOTIFICACAO_QUEUE = "consulta.notificacao.queue";
    public static final String NOTIFICACAO_ROUTING_KEY = "consulta.notificacao.routingKey";

    @Bean
    public Queue notificacaoQueue() {
        return new Queue(NOTIFICACAO_QUEUE, true); 
    }

    @Bean
    public DirectExchange exchange() {
        return new DirectExchange(CONSULTA_EXCHANGE);
    }

    @Bean
    public Binding binding(Queue notificacaoQueue, DirectExchange exchange) {
        return BindingBuilder.bind(notificacaoQueue).to(exchange).with(NOTIFICACAO_ROUTING_KEY);
    }

    @Bean
    public Jackson2JsonMessageConverter messageConverter() {
        return new Jackson2JsonMessageConverter();
    }
}

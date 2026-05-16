package br.com.mindflow.messaging;

import org.springframework.amqp.core.*;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.amqp.support.converter.SimpleMessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.ArrayList;
import java.util.List;

@Configuration
public class RabbitMQConfig {

    public static final String EXCHANGE = "mindflow.events";

    private static final List<String> FILAS = List.of(
            Eventos.CONSULTA_SOLICITADA,
            Eventos.CONSULTA_CONFIRMADA,
            Eventos.CONSULTA_RECUSADA,
            Eventos.CONSULTA_CANCELADA);

    @Bean
    public TopicExchange exchange() {
        return new TopicExchange(EXCHANGE);
    }

    @Bean
    public Declarables declarables() {
        var itens = new ArrayList<Declarable>();
        FILAS.forEach(nome -> {
            var fila = new Queue(nome, true);
            itens.add(fila);
            itens.add(BindingBuilder.bind(fila)
                    .to(exchange()).with(nome));
        });
        return new Declarables(itens);
    }

    @Bean
    public MessageConverter messageConverter() {
        return new SimpleMessageConverter();
    }
}
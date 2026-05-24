# MindFlow — Relatório de Integração MOM

**Disciplina:** Laboratório de Desenvolvimento de Aplicações Móveis e Distribuídas  
**Sprint:** 2 — Integração com Middleware Orientado a Mensagens  
**Aluno:** Jonathan Sena da Silva 
**Data:** Maio de 2026  

---

## 1. Escolha da ferramenta

Para a camada de mensageria do MindFlow foi escolhido o **RabbitMQ 3.13** com o plugin de gerenciamento habilitado (`rabbitmq:3.13-management-alpine`).

A escolha se justifica por três razões principais. Primeira, o RabbitMQ implementa nativamente o protocolo **AMQP 0-9-1**, que é o padrão de mensageria mais consolidado para sistemas distribuídos Java, com suporte oficial do Spring via `spring-boot-starter-amqp`. Segunda, o painel web integrado (`localhost:15672`) permite observar filas, mensagens e consumers em tempo real, o que facilita tanto o desenvolvimento quanto a geração de evidências para a entrega. Terceira, o modelo de exchange e bindings do RabbitMQ se encaixa naturalmente com o padrão de roteamento por evento adotado no projeto — cada tipo de evento tem sua própria fila nomeada.

Alternativas como Redis Pub/Sub foram consideradas, mas descartadas por não oferecerem persistência nativa de mensagens nem o modelo de consumer com confirmação de processamento (ACK), recursos essenciais para garantir que notificações não sejam perdidas em caso de falha momentânea do serviço.

---

## 2. Padrão utilizado

O MindFlow adota o padrão **Publish/Subscribe com roteamento por tópico (Topic Exchange)**. O backend publica eventos em um exchange central chamado `mindflow.events`. Cada evento possui uma routing key específica (ex: `consulta.solicitada`) que determina para qual fila a mensagem será roteada.

Esse padrão, descrito em Hohpe e Woolf (2003) como *Message Router* combinado com *Publish-Subscribe Channel*, permite que múltiplos consumers independentes processem o mesmo evento sem acoplamento entre si. No MindFlow, o consumer atual é o `ConsultaEventListener`, mas na Sprint 4 novos consumers poderão ser adicionados (ex: envio de e-mail, registro de auditoria) sem modificar o produtor.

```
Produtor ──► Exchange (mindflow.events) ──► Fila (consulta.solicitada) ──► Consumer
```

---

## 3. Implementação do produtor

O produtor é a classe `EventPublisher`, injetada no `ConsultaService`. A publicação ocorre imediatamente após a persistência da consulta no banco, dentro do mesmo método `@Transactional`.

```java
// ConsultaService.java
consultaRepo.save(consulta);
eventPublisher.publicar(Eventos.CONSULTA_SOLICITADA, consulta);
```

O `EventPublisher` serializa o objeto `ConsultaEvent` para JSON usando o `ObjectMapper` do Spring e publica via `RabbitTemplate`:

```java
byte[] payload = objectMapper.writeValueAsBytes(event);
Message message = MessageBuilder
    .withBody(payload)
    .setContentType(MessageProperties.CONTENT_TYPE_JSON)
    .build();
rabbitTemplate.send(RabbitMQConfig.EXCHANGE, routingKey, message);
```

Dois momentos distintos de publicação foram implementados, atendendo ao requisito mínimo da Sprint 2:

1. `consulta.solicitada` — ao criar uma consulta (`POST /consultas`)
2. `consulta.confirmada` — ao confirmar uma consulta (`PATCH /consultas/{id}/status`)

Adicionalmente, os eventos `consulta.recusada` e `consulta.cancelada`, também foram implementados, cobrindo o ciclo de vida quase completo.

---

## 4. Implementação do consumidor

O consumidor é a classe `ConsultaEventListener`, anotada com `@Component`. Cada método é anotado com `@RabbitListener` apontando para sua fila correspondente:

```java
@RabbitListener(queues = Eventos.CONSULTA_SOLICITADA)
public void onConsultaSolicitada(Message message) {
    var event = objectMapper.readValue(message.getBody(), ConsultaEvent.class);
    notificacaoService.notificar(event.psicologoId(), "Nova solicitação", ...);
}
```

O Spring AMQP gerencia automaticamente as threads dos consumers, que rodam de forma independente do servidor HTTP. Cada consumer envia um ACK ao RabbitMQ após o processamento bem-sucedido, garantindo que a mensagem seja removida da fila apenas quando processada.

O `NotificacaoService` recebe o evento e, por ora, registra a notificação via log. Na Sprint 4 será integrado ao Firebase Cloud Messaging para envio de push notifications reais.

---

## 5. Demonstração da assincronicidade

O log abaixo foi capturado durante um teste com Postman e demonstra que o evento é publicado e consumido em threads distintas, sem chamada REST direta:

```
[io-8080-exec-10] EventPublisher        : [MOM] Evento publicado: consulta.solicitada | consultaId: dcc51aa3...
[io-8080-exec-10] ConsultaService       : INSERT INTO consultas ...
[ntContainer#0-1] ConsultaEventListener : [consulta.solicitada] Nova consulta | paciente: João Silva
[ntContainer#0-1] NotificacaoService    : [NOTIFICACAO] → Dra. Ana Lima | titulo: 'Nova solicitação'
```

A thread `io-8080-exec-10` é gerenciada pelo Tomcat (HTTP). A thread `ntContainer#0-1` é gerenciada pelo Spring AMQP (RabbitMQ). O consumer processa o evento de forma completamente assíncrona — o cliente HTTP já recebeu a resposta `201 Created` quando o consumer ainda estava executando.

---

## 6. Desafios encontrados e soluções

**Desafio 1 — Compatibilidade do conversor de mensagens com Spring Boot 4**

O `Jackson2JsonMessageConverter` foi marcado como depreciado no Spring AMQP 4.0, que migrou para Jackson 3 (`tools.jackson`). A solução adotada foi usar o `SimpleMessageConverter` combinado com serialização manual via `ObjectMapper`:

```java
byte[] payload = objectMapper.writeValueAsBytes(event);
```

Isso evita dependência do conversor depreciado e mantém o controle explícito da serialização, o que é mais transparente para fins de documentação e debug.

**Desafio 2 — Permissão de arquivo no container RabbitMQ**

O container do RabbitMQ apresentou erro `eacces` no arquivo `.erlang.cookie` na primeira inicialização. O erro ocorreu porque o volume montado pelo Podman preservou permissões de uma inicialização anterior com usuário diferente. A solução foi executar `podman compose down -v` para remover os volumes e reiniciar os containers do zero.

**Desafio 3 — Ordem de inicialização dos containers**

O Spring tentava conectar ao RabbitMQ antes do container estar pronto para aceitar conexões. A solução foi adicionar `healthcheck` no `compose.yml` com `condition: service_healthy` no `depends_on` do serviço da API, garantindo que o Spring só inicia após o RabbitMQ estar operacional.

---

## 7. Conclusão

A integração com o RabbitMQ foi implementada com sucesso, cobrindo todos os requisitos da Sprint 2: MOM configurado e operacional, produtor e consumidor implementados em múltiplos pontos do fluxo, documentação dos eventos e demonstração comprovada de comunicação assíncrona entre threads distintas.

A arquitetura orientada a eventos adotada segue os padrões descritos em Hohpe e Woolf (2003) e está alinhada com os princípios de Event-Driven Architecture discutidos em Richardson (2018). A estrutura está preparada para evolução na Sprint 4, quando o `NotificacaoService` será integrado ao Firebase Cloud Messaging para envio de push notifications reais aos apps Flutter.

---

## Referências

HOHPE, Gregor; WOOLF, Bobby. **Enterprise Integration Patterns**: designing, building, and deploying messaging solutions. Boston: Addison-Wesley, 2003.

RICHARDSON, Chris. **Microservices patterns**: with examples in Java. Shelter Island: Manning, 2018.

MARTIN, Robert C. **Arquitetura limpa**: o guia do artesão para estrutura e design de software. Rio de Janeiro: Alta Books, 2019.
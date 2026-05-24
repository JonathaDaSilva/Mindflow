# MindFlow — Documentação dos Eventos (MOM)

**Sprint:** 2 — Integração com Middleware Orientado a Mensagens  
**MOM utilizado:** RabbitMQ 3.13  
**Exchange:** `mindflow.events` (TopicExchange)  
**Protocolo:** AMQP 0-9-1  

---

## Arquitetura de eventos

```
ConsultaService (Produtor)
        │
        │ rabbitTemplate.convertAndSend("mindflow.events", routingKey, event)
        ▼
TopicExchange: mindflow.events
        │
        ├──► Queue: consulta.solicitada  ──► ConsultaEventListener.onConsultaSolicitada()
        ├──► Queue: consulta.confirmada  ──► ConsultaEventListener.onConsultaConfirmada()
        ├──► Queue: consulta.recusada    ──► ConsultaEventListener.onConsultaRecusada()
        ├──► Queue: consulta.concluida   ──► ConsultaEventListener.onConsultaConcluida()
        └──► Queue: consulta.cancelada   ──► ConsultaEventListener.onConsultaCancelada()
```

---

## Tabela de eventos

| # | Nome do evento | Routing Key | Produtor | Consumidor | Gatilho |
|---|---|---|---|---|---|
| 1 | Consulta Solicitada | `consulta.solicitada` | `ConsultaService.solicitar()` | `ConsultaEventListener` | Paciente agenda uma consulta |
| 2 | Consulta Confirmada | `consulta.confirmada` | `ConsultaService.atualizarStatus()` | `ConsultaEventListener` | Psicólogo confirma a consulta |
| 3 | Consulta Recusada | `consulta.recusada` | `ConsultaService.atualizarStatus()` | `ConsultaEventListener` | Psicólogo recusa a consulta |
| 4 | Consulta Cancelada | `consulta.cancelada` | `ConsultaService.cancelar()` | `ConsultaEventListener` | Qualquer parte cancela com 24h+ |

---

## Payload padrão — `ConsultaEvent`

Todos os eventos compartilham o mesmo payload. O campo `status` indica qual transição ocorreu.

```json
{
  "consultaId":  "dcc51aa3-56f2-4694-8a5f-f7c13c8860ce",
  "pacienteId":  "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "psicologoId": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
  "nomePaciente":  "João Silva",
  "nomePsicologo": "Dra. Ana Lima",
  "status":    "SOLICITADA",
  "dataHora":  "2026-06-08T09:00:00",
  "timestamp": "2026-05-16T16:41:03.121Z"
}
```

| Campo | Tipo | Descrição |
|---|---|---|
| `consultaId` | UUID | Identificador único da consulta |
| `pacienteId` | UUID | ID do usuário paciente |
| `psicologoId` | UUID | ID do usuário psicólogo |
| `nomePaciente` | String | Nome do paciente para exibição |
| `nomePsicologo` | String | Nome do psicólogo para exibição |
| `status` | String (enum) | Status atual: SOLICITADA, CONFIRMADA, RECUSADA, EM_ANDAMENTO, CONCLUIDA, CANCELADA |
| `dataHora` | String (ISO 8601) | Data e hora da consulta |
| `timestamp` | String (ISO 8601) | Momento em que o evento foi publicado |

---

## Detalhamento por evento

### 1. `consulta.solicitada`

**Quando:** paciente chama `POST /consultas`  
**Ação do consumer:** notifica o psicólogo — log no servidor + push FCM (Sprint 4)

```
[consulta.solicitada] Nova consulta | paciente: João Silva | psicólogo: Dra. Ana Lima | data: 2026-06-08T09:00
[NOTIFICACAO] → Dra. Ana Lima | titulo: 'Nova solicitação de consulta' | corpo: 'João Silva solicitou uma consulta para 08/06/2026 às 09:00'
```

---

### 2. `consulta.confirmada`

**Quando:** psicólogo chama `PATCH /consultas/{id}/status` com `{"status": "CONFIRMADA"}`  
**Ação do consumer:** notifica o paciente de que foi aceito

```
[consulta.confirmada] Consulta confirmada | paciente: João Silva | data: 2026-06-08T09:00
[NOTIFICACAO] → João Silva | titulo: 'Consulta confirmada! ✅' | corpo: 'Sua consulta com Dra. Ana Lima foi confirmada para 08/06/2026 às 09:00'
```

---

### 3. `consulta.recusada`

**Quando:** psicólogo chama `PATCH /consultas/{id}/status` com `{"status": "RECUSADA"}`  
**Ação do consumer:** notifica o paciente para remarcar

```
[consulta.recusada] Consulta recusada | paciente: João Silva
[NOTIFICACAO] → João Silva | titulo: 'Consulta não disponível' | corpo: 'Dra. Ana Lima não pôde aceitar sua solicitação para 08/06/2026 às 09:00. Tente outro horário.'
```

---

### 4. `consulta.cancelada`

**Quando:** qualquer parte chama `PATCH /consultas/{id}/cancelar` com motivo e 24h+ de antecedência  
**Ação do consumer:** notifica **ambas** as partes

```
[consulta.cancelada] Consulta cancelada | consultaId: dcc51aa3-...
[NOTIFICACAO] → João Silva    | titulo: 'Consulta cancelada' | corpo: 'Sua consulta de 08/06/2026 às 09:00 foi cancelada'
[NOTIFICACAO] → Dra. Ana Lima | titulo: 'Consulta cancelada' | corpo: 'A consulta com João Silva em 08/06/2026 às 09:00 foi cancelada'
```

---

## Configuração das filas

**Tipo de exchange:** `TopicExchange` — permite filtrar por padrão de routing key  
**Durabilidade:** todas as filas são `durable: true` — sobrevivem a restart do RabbitMQ  
**Serialização:** JSON via `SimpleMessageConverter` + `ObjectMapper` (Jackson 3 / Spring AMQP 4)

```java
// RabbitMQConfig.java
public static final String EXCHANGE = "mindflow.events";

private static final List<String> FILAS = List.of(
    "consulta.solicitada",
    "consulta.confirmada",
    "consulta.recusada",
    "consulta.cancelada"
);
```

---

## Evidência de funcionamento

Log capturado durante teste com Postman (Sprint 2):

```
[io-8080-exec-10] ConsultaService        : Consulta criada: dcc51aa3-56f2-4694-8a5f-f7c13c8860ce
[io-8080-exec-10] EventPublisher         : [MOM] Evento publicado: consulta.solicitada | consultaId: dcc51aa3-56f2-4694-8a5f-f7c13c8860ce
[ntContainer#0-1] ConsultaEventListener  : [consulta.solicitada] Nova consulta | paciente: João Silva | psicólogo: Dra. Ana Lima | data: 2026-06-08T08:00
[ntContainer#0-1] NotificacaoService     : [NOTIFICACAO] → Dra. Ana Lima | titulo: 'Nova solicitação de consulta'
```

> **Prova de assincronicidade:** o evento foi publicado pela thread `io-8080-exec-10` (HTTP)
> e consumido pela thread `ntContainer#0-1` (RabbitMQ consumer) — threads distintas,
> sem chamada REST direta entre produtor e consumidor.

---

## Fluxo de notificações por perfil

| Evento | Notifica Paciente | Notifica Psicólogo |
|---|---|---|
| `consulta.solicitada` | ✗ | ✅ |
| `consulta.confirmada` | ✅ | ✗ |
| `consulta.recusada` | ✅ | ✗ |
| `consulta.cancelada` | ✅ | ✅ |

---

## Evolução prevista — Sprint 4

Na Sprint 4 o método `NotificacaoService.notificar()` será implementado com chamada real ao **Firebase Cloud Messaging (FCM)**. A estrutura já está preparada:

```java
// Sprint 4: implementar chamada HTTP para FCM
// private void enviarPushFCM(String token, String titulo, String corpo) { ... }
```

O FCM token é registrado pelo app Flutter via `PATCH /usuarios/me/fcm-token` após o login.
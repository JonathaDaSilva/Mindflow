# MindFlow API

Sistema distribuído de agendamento de consultas psicológicas, desenvolvido como Projeto Integrador da disciplina **Laboratório de Desenvolvimento de Aplicações Móveis e Distribuídas** — PUC Minas, Engenharia de Software, 5º Período, 1º Semestre 2026.

---

## Sobre o projeto

O MindFlow conecta **pacientes** a **psicólogos** por meio de dois aplicativos móveis distintos (Flutter), um backend REST (Spring Boot 4 + Java 21) e comunicação assíncrona orientada a eventos via RabbitMQ.

| Componente | Tecnologia | Versão |
|---|---|---|
| Backend REST | Spring Boot + Java | 4.0 + Java 21 |
| Banco de dados | PostgreSQL | 15 |
| Mensageria (MOM) | RabbitMQ | 3.13 |
| App paciente | Flutter / Dart | 3.10+ |
| App psicólogo | Flutter / Dart | 3.10+ |
| Containerização | Podman + Compose | — |
| Autenticação | JWT (jjwt) | 0.12.6 |

---

## Estrutura do repositório

```
mindflow/
├── mindflow-api/            # Backend Spring Boot
│   ├── src/
│   ├── Dockerfile
│   └── pom.xml
├── mindflow_paciente/       # App Flutter — paciente
│   └── lib/screens/
├── mindflow_psicologo/      # App Flutter — psicólogo
│   └── lib/screens/
├── mindflow_shared/         # Pacote Flutter compartilhado
│   └── lib/
│       ├── theme/
│       ├── models/
│       └── services/
├── docs/
│   ├── proposta.md
│   ├── requisitos.md
│   ├── arquitetura.md
│   ├── eventos_mom.md       # Documentação dos eventos RabbitMQ
│   └── relatorio_integracao_mom.md
├── postman/
│   └── mindflow.postman_collection.json
├── compose.yml              # Podman — API + PostgreSQL + RabbitMQ
└── README.md
```

---

## Pré-requisitos

| Ferramenta | Versão mínima | Instalação |
|---|---|---|
| Java | 21 | [adoptium.net](https://adoptium.net) |
| Maven | 3.9+ | [maven.apache.org](https://maven.apache.org) |
| Podman | 4.0+ | [podman.io](https://podman.io) |
| podman-compose | qualquer | `pip install podman-compose` |
| Flutter | 3.10+ | [flutter.dev](https://flutter.dev) |

---

## Como rodar

### Opção 1 — Tudo via Podman (recomendado)

Sobe API + PostgreSQL + RabbitMQ em um único comando:

```bash
# cd mindflow-api
podman compose up -d --build
```

Aguarde o build e a inicialização (~2 min na primeira vez). Acompanhe os logs:

```bash
podman logs -f mindflow-api
```

Quando aparecer `Started MindflowApiApplication`, a API está pronta.

### Opção 2 — Backend local + infraestrutura via Podman

```bash
# 1. Sobe PostgreSQL e RabbitMQ
podman compose up -d postgres rabbitmq

# 2. Roda a API localmente
cd mindflow-api
mvn spring-boot:run
```

---

## Serviços disponíveis

| Serviço | URL | Credenciais |
|---|---|---|
| API REST | http://localhost:8080/api | — |
| Health check | http://localhost:8080/actuator/health | — |
| RabbitMQ Painel | http://localhost:15672 | guest / guest |
| PostgreSQL | localhost:5432 | mindflow_user / mindflow_password |

---

## Apps Flutter

### App Paciente

```bash
cd mindflow_paciente
flutter pub get
flutter run
```

### App Psicólogo

```bash
cd mindflow_psicologo
flutter pub get
flutter run
```

> **Emulador Android:** a URL base já está configurada para `10.0.2.2:8080` (localhost do host visto pelo emulador).  
> **Dispositivo físico:** altere `baseUrl` em `mindflow_shared/lib/services/api_client.dart` para o IP da sua máquina na rede local.

---

## Endpoints principais — Sprint 1 e 2

### Autenticação (público)

| Método | Endpoint | Descrição |
|---|---|---|
| POST | `/auth/registrar` | Registra usuário + perfil em uma transação |
| POST | `/auth/login` | Retorna token JWT |

### Usuário (autenticado)

| Método | Endpoint | Descrição |
|---|---|---|
| GET | `/usuarios/me` | Dados do usuário logado |
| PUT | `/usuarios/me` | Atualiza nome |
| PATCH | `/usuarios/me/fcm-token` | Registra token FCM para push |

### Paciente

| Método | Endpoint | Descrição |
|---|---|---|
| GET | `/pacientes/perfil` | Perfil completo (inclui dados sensíveis) |
| PUT | `/pacientes/perfil` | Atualiza perfil |

### Psicólogo

| Método | Endpoint | Descrição |
|---|---|---|
| GET | `/psicologos` | Lista psicólogos ativos |
| GET | `/psicologos/perfil` | Perfil do psicólogo logado |
| PUT | `/psicologos/perfil` | Atualiza perfil profissional |

### Disponibilidade

| Método | Endpoint | Descrição |
|---|---|---|
| PUT | `/disponibilidades` | Salva agenda semanal completa |
| GET | `/disponibilidades` | Lê agenda do psicólogo logado |
| GET | `/disponibilidades/{id}/slots?data=YYYY-MM-DD` | Slots livres em uma data |
| GET | `/disponibilidades/{id}/proximo-disponivel` | Primeiro dia com slot livre |

### Consultas

| Método | Endpoint | Descrição |
|---|---|---|
| POST | `/consultas` | Paciente solicita consulta |
| GET | `/consultas/minhas` | Consultas do paciente logado |
| GET | `/consultas/pendentes` | Solicitações pendentes (psicólogo) |
| GET | `/consultas/agenda` | Todas as consultas (psicólogo) |
| PATCH | `/consultas/{id}/status` | Confirmar ou recusar (psicólogo) |
| PATCH | `/consultas/{id}/cancelar` | Cancelar com 24h de antecedência |

> Todos os endpoints (exceto `/auth/**`) exigem: `Authorization: Bearer <token>`

---

## Eventos RabbitMQ (Sprint 2)

| Evento | Quando | Notifica |
|---|---|---|
| `consulta.solicitada` | Paciente agenda | Psicólogo |
| `consulta.confirmada` | Psicólogo confirma | Paciente |
| `consulta.recusada` | Psicólogo recusa | Paciente |
| `consulta.cancelada` | Qualquer parte cancela | Ambos |

Consulte [`docs/eventos_mom.md`](docs/eventos_mom.md) para o payload completo e detalhes de cada evento.

---

## Arquitetura de camadas (backend)

```
HTTP Request
     │
     ▼
Controller  → valida e delega (sem lógica de negócio)
     │
     ▼
Service     → regras de negócio + publica eventos no RabbitMQ
     │         │
     ▼         ▼
Repository    EventPublisher → RabbitMQ → ConsultaEventListener
     │                                          │
     ▼                                          ▼
PostgreSQL                              NotificacaoService
                                        (push FCM — Sprint 4)
```

Princípios aplicados: **Clean Architecture**, **SOLID**, **Event-Driven Architecture (EDA)**.

---

## Variáveis de ambiente

| Variável | Padrão | Descrição |
|---|---|---|
| `DB_USER` | `mindflow_user` | Usuário PostgreSQL |
| `DB_PASS` | `mindflow_password` | Senha PostgreSQL |
| `RABBIT_USER` | `guest` | Usuário RabbitMQ |
| `RABBIT_PASS` | `guest` | Senha RabbitMQ |
| `SPRING_DATASOURCE_URL` | `jdbc:postgresql://postgres:5432/mindflow_db` | URL do banco |
| `SPRING_RABBITMQ_HOST` | `rabbitmq` | Host do RabbitMQ |
| `jwt.secret` | definido no yml | Chave JWT (mín. 32 chars) |
| `jwt.expiration` | `86400000` | Expiração do token (24h em ms) |

---

## Sprints

| Sprint | Foco | Prazo | Status |
|---|---|---|---|
| Sprint 1 | Arquitetura + Backend REST + Auth JWT | 11/05/2026 |  Entregue |
| Sprint 2 | Integração RabbitMQ (MOM) | 25/05/2026 |  Entregue |
| Sprint 3 | App Flutter — Paciente | 15/06/2026 |  Em andamento |
| Sprint 4 | App Flutter — Psicólogo + Entrega Final | 03/07/2026 |  Em andamento |

---

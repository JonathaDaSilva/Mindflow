# MindFlow 
 
Sistema distribuído de agendamento de consultas psicológicas, desenvolvido como Projeto Integrador da disciplina **Laboratório de Desenvolvimento de Aplicações Móveis e Distribuídas** — PUC Minas, Engenharia de Software, 5º Período, 1º Semestre 2026.
 
---
 
## Sobre o projeto
 
O MindFlow conecta **pacientes** a **psicólogos** por meio de dois aplicativos móveis distintos (Flutter), um backend REST (Spring Boot) e comunicação assíncrona orientada a eventos via RabbitMQ.
 
| Componente | Tecnologia |
|---|---|
| Backend REST | Spring Boot 3 + Java 21 |
| Banco de dados | PostgreSQL 16 |
| Mensageria (MOM) | RabbitMQ 3 |
| App paciente | Flutter / Dart |
| App psicólogo | Flutter / Dart |
| Containerização | Podman + Compose |
| Autenticação | JWT (jjwt 0.12.6) |
 
---

## Estrutura do repositório
 
```
mindflow/
├── mindflow-api/          # Backend Spring Boot
├── mindflow_paciente/     # App Flutter — paciente
├── mindflow_psicologo/    # App Flutter — psicólogo
├── docs/
│   ├── proposta.md        # Proposta de domínio
│   ├── requisitos.md      # Requisitos funcionais e não funcionais
│   └── arquitetura.md     # Documento de arquitetura
├── postman/
│   └── mindflow.json      # Coleção de testes Postman
├── compose.yml            # Podman — PostgreSQL + RabbitMQ
└── README.md
```

---
 
## Pré-requisitos
 
- Java 21+
- Maven 3.9+
- Podman + podman-compose (`pip install podman-compose`)
- Flutter 3.10+
---
 
## Como rodar
 
### 1. Subir infraestrutura (PostgreSQL + RabbitMQ)
 
```bash
podman compose up -d
```
 
Aguarde os containers iniciarem. Verifique com:
 
```bash
podman ps
```
 
| Serviço | URL |
|---|---|
| PostgreSQL | `localhost:5432` |
| RabbitMQ API | `localhost:5672` |
| RabbitMQ Painel | http://localhost:15672 (admin/admin) |
 
### 2. Rodar o backend
 
```bash
cd mindflow-api
mvn spring-boot:run
```
 
A API sobe em: **http://localhost:8080/api/**

### 3. Verificar saúde da API
 
```
GET http://localhost:8080/actuator/health
```
 
---

## Arquitetura de camadas (backend)
 
```
Controller → Service → Repository → Entity
                ↓
           Messaging (RabbitMQ) 
```
 
Princípios aplicados: **Clean Architecture**, **SOLID**, **Event-Driven Architecture (EDA)**.
 
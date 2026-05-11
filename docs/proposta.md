# MindFlow — Proposta de Domínio

**Disciplina:** Laboratório de Desenvolvimento de Aplicações Móveis e Distribuídas  
**Curso:** Engenharia de Software — PUC Minas  
**Período:** 5º Período — Noite | 1º Semestre 2026  
**Aluno:** Jonathan Sena da Silva
**Professores:** Cleiton Silva Tavares e Cristiano de Macedo Neto  

---

## 1. Descrição do domínio

O **MindFlow** é uma plataforma de agendamento de consultas psicológicas que conecta pacientes a psicólogos de forma digital, segura e acessível. O sistema permite que pacientes encontrem profissionais disponíveis, agendem sessões presenciais ou remotas e acompanhem o status de seus atendimentos em tempo real.

A motivação do projeto parte de uma necessidade real: o acesso à saúde mental ainda é limitado para grande parte da população, seja por dificuldade de encontrar profissionais disponíveis, por barreiras geográficas ou pela falta de ferramentas que facilitem o agendamento. O MindFlow propõe reduzir essas barreiras por meio de tecnologia.

---

## 2. Justificativa

O domínio de agendamento de consultas psicológicas foi escolhido por:

- Possuir **distinção clara entre cliente e prestador de serviços**, atendendo ao requisito arquitetural da disciplina
- Apresentar um **ciclo de vida de estados rico** (solicitada → confirmada → em andamento → concluída / cancelada), ideal para demonstrar arquitetura orientada a eventos com RabbitMQ
- Ser um **problema real e relevante**, com potencial de produto, o que facilita a defesa das decisões de design no relatório final
- Permitir **modalidades presencial e remota**, adicionando complexidade de domínio sem aumentar a complexidade técnica

---

## 3. Perfis de usuário

### 3.1 Paciente (cliente)

O paciente é o usuário que busca atendimento psicológico. Suas responsabilidades no sistema são:

- Cadastrar-se na plataforma informando dados pessoais e preferência de pagamento
- Buscar psicólogos disponíveis filtrando por especialidade, regime de trabalho e valor
- Solicitar agendamento de consulta em horário disponível
- Acompanhar o status da consulta (aguardando confirmação, confirmada, em andamento, concluída)
- Cancelar consulta com até 24 horas de antecedência
- Solicitar atendimento emergencial em situação de crise
- Avaliar o psicólogo após a conclusão da sessão

### 3.2 Psicólogo (prestador de serviços)

O psicólogo é o profissional que oferece o serviço de atendimento. Suas responsabilidades são:

- Cadastrar-se com dados profissionais (CRP, especialidade, bio)
- Definir regime de trabalho (presencial, remoto ou híbrido)
- Cadastrar endereço para atendimentos presenciais
- Configurar disponibilidade semanal de horários
- Estabelecer duração e valor da sessão
- Optar por receber demandas de atendimento emergencial
- Confirmar ou recusar solicitações de consulta
- Cadastrar link da sala virtual até 24 horas antes da sessão confirmada
- Cancelar consulta com até 24 horas de antecedência
- Receber lembretes das consultas do dia

---

## 4. Principais funcionalidades

| Funcionalidade | Perfil |
|---|---|
| Cadastro com criação de perfil em uma transação | Ambos |
| Autenticação JWT stateless | Ambos |
| Busca de psicólogos por especialidade e regime | Paciente |
| Agendamento de consulta com verificação de conflito | Paciente |
| Atendimento emergencial (somente remoto) | Paciente |
| Configuração de agenda semanal | Psicólogo |
| Confirmação / recusa de solicitações | Psicólogo |
| Cadastro de link de sala virtual | Psicólogo |
| Notificações assíncronas via RabbitMQ | Ambos |
| Lembretes automáticos por job agendado | Ambos |
| Avaliação pós-consulta | Paciente |

---

## 5. Fluxo principal

```
Paciente solicita consulta
        ↓
Backend salva + publica evento "consulta.solicitada" no RabbitMQ
        ↓
Consumer notifica o psicólogo (push FCM)
        ↓
Psicólogo aceita → evento "consulta.confirmada"
        ↓
Consumer notifica o paciente
        ↓
Psicólogo cadastra link da sala (se remoto)
        ↓
Sessão ocorre → "consulta.concluida"
        ↓
Paciente avalia o psicólogo
```

---

## 6. Restrições e regras de negócio principais

- Cancelamento permitido somente com **mais de 24 horas** de antecedência
- Link da sala virtual deve ser cadastrado em até **24 horas antes** da sessão
- Atendimento emergencial é **exclusivamente remoto**
- No emergencial, o **primeiro psicólogo** a aceitar assume o atendimento (first-come-first-served com controle de concorrência)
- A plataforma **não processa pagamentos** — apenas registra a forma de pagamento preferida
- Dados de observações clínicas são **sensíveis (LGPD)** e não são expostos em listagens gerais
# MindFlow — Documentação de Requisitos

Este documento detalha os Requisitos Funcionais (RF), Requisitos Não Funcionais (RNF) e Regras de Negócio (RN) do sistema MindFlow, classificados por nível de complexidade.

## 1. Requisitos Funcionais

| Numeração | Requisito (Diretamente explicado) | Classificação Complexidade |
| :--- | :--- | :--- |
| **RF01** | Permitir o cadastro de um utilizador e o seu perfil (paciente ou psicólogo) ao mesmo tempo. | Média |
| **RF02** | Realizar o login via e-mail e palavra-passe, garantindo acesso seguro por até 24 horas. | Média |
| **RF03** | Permitir que o paciente registe, visualize e edite os seus dados pessoais e histórico de saúde. | Baixa |
| **RF04** | Permitir que o psicólogo registe, visualize e edite os seus dados profissionais, preço e horários. | Baixa |
| **RF05** | Permitir que o paciente procure psicólogos filtrando por especialidade, preço, horários e modelo de trabalho. | Média |
| **RF06** | Mostrar os horários livres do psicólogo, cruzando a sua disponibilidade geral com as consultas já marcadas. | Alta |
| **RF07** | Permitir que o paciente solicite o agendamento num horário livre, impedindo choques de agenda. | Média |
| **RF08** | Permitir que o psicólogo receba, aceite ou recuse solicitações de novas consultas. | Baixa |
| **RF09** | Controlar o andamento da consulta desde a solicitação até à sua conclusão, cancelamento ou falta. | Média |
| **RF10** | Permitir o cancelamento da consulta por qualquer uma das partes, desde que falte mais de 24h para o início. | Baixa |
| **RF11** | Permitir que o psicólogo adicione o link da videochamada no máximo 24 horas antes da consulta acontecer. | Baixa |
| **RF12** | Permitir que pacientes em crise peçam ajuda imediata; o primeiro psicólogo disponível que aceitar assume o caso. | Alta |
| **RF13** | Permitir que o paciente guarde a sua forma de pagamento favorita (apenas para registo, sem cobrança automática). | Baixa |
| **RF14** | Enviar notificações automáticas em tempo real para as aplicações sempre que o estado de uma consulta mudar. | Alta |
| **RF15** | Enviar lembretes automáticos de consultas agendadas para os pacientes e resumos diários para os psicólogos. | Média |
| **RF16** | Permitir que o paciente atribua uma nota (1 a 5) e um comentário para o psicólogo após a consulta. | Baixa |
| **RF17** | Permitir que ambos vejam o histórico de todas as consultas passadas, incluindo dados de quem atendeu/foi atendido. | Baixa |
| **RF18** | Permitir que o psicólogo bloqueie dias na agenda (como férias) para que ninguém consiga marcar horários nesse período. | Média |

## 2. Requisitos Não Funcionais

| Numeração | Requisito Não Funcional | Classificação Complexidade |
| :--- | :--- | :--- |
| **RNF01** | O sistema não deve guardar a "sessão" do utilizador na memória; cada ação deve ser validada por uma chave de acesso segura. | Média |
| **RNF02** | Proteger os dados de saúde do paciente, garantindo que só ele os veja e que isso não fique guardado em nenhum registo técnico. | Média |
| **RNF03** | Garantir que o cadastro grave tudo ou nada: se houver erro a meio da criação da conta, nenhum dado incompleto pode ser guardado. | Baixa |
| **RNF04** | Fazer com que o envio de mensagens e notificações funcione de forma independente e em segundo plano para não bloquear o sistema. | Alta |
| **RNF05** | Organizar o código do sistema em camadas bem separadas, onde a parte visual não se mistura com as regras de negócio. | Média |
| **RNF06** | Garantir que o sistema seja rápido e responda a procuras e carregamentos simples em menos de meio segundo. | Média |
| **RNF07** | Empacotar o sistema e a base de dados de forma a que possam ser instalados e executados rapidamente em qualquer computador. | Média |
| **RNF08** | Evitar que dois psicólogos aceitem o mesmo atendimento emergencial ao mesmo tempo, bloqueando a vaga para o primeiro que clicar. | Alta |
| **RNF09** | Manter o histórico de código organizado, guardando o progresso etapa por etapa e não tudo de uma vez no final. | Baixa |
| **RNF10** | Criar um manual prático listando todos os links do sistema, mostrando exemplos de como enviar e receber os dados. | Baixa |

## 3. Regras de Negócio

| Numeração | Regra de Restrição | Classificação Complexidade |
| :--- | :--- | :--- |
| **RN01** | Não é permitido criar duas contas com o mesmo endereço de e-mail. | Baixa |
| **RN02** | A palavra-passe do utilizador deve ser guardada de forma baralhada e ilegível na base de dados. | Baixa |
| **RN03** | O sistema deve bloquear qualquer tentativa de cancelamento se faltar menos de 24 horas para a consulta. | Baixa |
| **RN04** | Pedidos de emergência só aparecem para psicólogos que atendem online; quem atende apenas presencialmente não recebe o alerta. | Baixa |
| **RN05** | O link da videochamada só pode ser guardado se a consulta já foi aceite pelo psicólogo e a data/hora ainda não passou. | Baixa |
| **RN06** | Apenas psicólogos podem aceder à ficha completa de um paciente. | Baixa |
| **RN07** | Apenas perfis de paciente podem solicitar o agendamento de uma nova consulta. | Baixa |
| **RN08** | O sistema deve tratar valores financeiros com exatidão para não perder ou somar cêntimos indevidamente. | Baixa |
| **RN09** | Anotações médicas nunca podem aparecer nos relatórios técnicos de monitorização dos servidores. | Baixa |
| **RN10** | Na emergência, assim que um psicólogo aceita o chamado, o sistema bloqueia o botão para todos os outros instantaneamente. | Alta |
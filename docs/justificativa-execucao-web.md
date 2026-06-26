# MindFlow — Justificativa de Execução via Flutter Web (Chrome)

**Disciplina:** Laboratório de Desenvolvimento de Aplicações Móveis e Distribuídas
**Sprint:** 3
**Aluno:** Jonathan Sena da Silva
**Data:** Junho de 2026

---

## 1. Contexto

A demonstração completa do MindFlow exige dois clientes rodando simultaneamente — o app do paciente e o app do psicólogo — para evidenciar o fluxo de ponta a ponta (solicitação → confirmação → link de sessão → conclusão → avaliação). Até a Sprint 2, essa demonstração era feita com dois emuladores Android abertos ao mesmo tempo no Android Studio.

Na máquina utilizada para a entrega da Sprint 3, dois emuladores Android simultâneos excedem a capacidade de RAM/CPU disponível, causando lentidão severa e instabilidade (travamentos, ANRs e timeouts de rede). Isso tornou inviável gravar uma demonstração fluida do fluxo completo usando dois emuladores.

## 2. Solução adotada

Para viabilizar a demonstração, os dois aplicativos Flutter foram executados como **Flutter Web** (`flutter run -d chrome`), abrindo cada app em uma aba/janela do Chrome. Essa alternativa é suportada nativamente pelo Flutter e usa o mesmo código-fonte Dart dos apps Android — não há fork de projeto nem implementação paralela.

Para isso, três ajustes foram necessários no código, todos preservando 100% do comportamento original em Android/iOS:

1. **`ApiClient.baseUrl`** passou a ser um getter condicionado por `kIsWeb`: usa `http://localhost:8080/api` no Chrome e mantém `http://10.0.2.2:8080/api` no emulador Android (loopback do emulador para o host).
2. **`NotificacaoLocalService`** foi dividido em duas implementações (`_native.dart` e `_web.dart`) selecionadas por *conditional export* (`dart.library.html`), pois o pacote `flutter_local_notifications` não tem suporte à Web. No Chrome, a notificação do sistema operacional simplesmente não é exibida — o restante do fluxo (atualização de status, badge de pendentes, polling) continua funcionando normalmente.
3. **CORS** foi habilitado no Spring Boot (`SecurityConfig.corsConfigurationSource()`), liberando `http://localhost:*`, já que o navegador bloqueia por padrão requisições cross-origin que o emulador Android nunca bloqueou.

## 3. Impacto sobre o SSE (Server-Sent Events)

O ponto mais relevante desta mudança: a camada de **tempo real via SSE** (`GET /notificacoes/stream`, implementada na Sprint 2/3 como consumidor das mensagens do RabbitMQ) **não pôde ser demonstrada ao vivo pelo navegador**.

O motivo é técnico, não uma limitação do backend: no Flutter Web, requisições HTTP passam pelo `XMLHttpRequest`/`fetch` do próprio navegador, que não expõe os eventos de um stream de forma incremental como o `http.Client.send()` faz em Dart nativo (Android/iOS/desktop). Para consumir SSE de fato no navegador seria necessário usar a API nativa `EventSource` do JavaScript via interop, o que estava fora do escopo desta correção pontual de ambiente.

**Isso não significa que o SSE parou de funcionar** — o endpoint `/notificacoes/stream` continua ativo e funcional no backend, publicando os mesmos eventos vindos do RabbitMQ (`consulta.solicitada`, `consulta.confirmada`, etc.), exatamente como demonstrado na Sprint 2. A única mudança é que o **cliente Web** não se conecta a ele.

A arquitetura do `ConsultaMonitorService`, descrita desde a Sprint 2, já previa duas camadas redundantes por design:

```
1. SSE  → tempo real (GET /notificacoes/stream)
2. Poll → fallback a cada 30s (cobre app em background ou SSE indisponível)
```

Quando executado na Web, o app simplesmente **pula a camada 1 e usa apenas a camada 2** (`if (!kIsWeb) _conectarSSE();`). Ou seja, a própria resiliência projetada desde a Sprint 2 — pensada originalmente para cobrir quedas de conexão — é o que garante que o app continue funcional (com até 30s de defasagem) mesmo sem SSE no navegador.

## 4. Como evidenciar o SSE para o professor

Como o SSE em si não depende do cliente Flutter (ele é uma característica do backend Spring consumindo o RabbitMQ), a recomendação é demonstrá-lo de forma desacoplada da interface, da mesma forma que a assincronicidade do RabbitMQ foi evidenciada na Sprint 2 (ver `docs/relatorioIntegracao.md`, seção 5):

- Rodar `curl -N -H "Authorization: Bearer <token>" http://localhost:8080/api/notificacoes/stream` em um terminal, mantendo a conexão aberta.
- Em outra janela, disparar uma ação que gere evento (ex: `POST /consultas` ou `PATCH /consultas/{id}/status`) via Postman.
- O terminal com o `curl` recebe a linha `data: {...}` em tempo real — prova de que o stream funciona independentemente do cliente usado.
- Essa evidência pode ser gravada em vídeo curto e anexada junto ao vídeo principal da Sprint 3 (rodado no Chrome), com a observação de que o app mobile (Android/iOS) consome esse mesmo stream nativamente, como ficará demonstrado quando o ambiente de testes contar com hardware suficiente para os dois emuladores simultâneos.

## 5. Resumo

| Item | Em Android (2 emuladores) | Em Chrome (workaround desta sprint) |
|---|---|---|
| Notificações de status (CONFIRMADA, CONCLUIDA, etc.) | SSE em tempo real + polling 30s | Apenas polling 30s |
| Notificação push/local do SO | Sim (`flutter_local_notifications`) | Não exibida (stub no-op) |
| Atualização de status, link de sessão, avaliação | Funciona | Funciona |
| Backend (`/notificacoes/stream`, RabbitMQ) | Inalterado | Inalterado |

O comportamento divergente é estritamente limitado à camada de transporte de notificação em tempo real no cliente — todo o restante do fluxo funcional da Sprint 3 (avaliação pós-consulta, link de sessão, marcação como concluída, perfil e forma de pagamento) foi verificado e funciona de forma idêntica em ambas as plataformas.

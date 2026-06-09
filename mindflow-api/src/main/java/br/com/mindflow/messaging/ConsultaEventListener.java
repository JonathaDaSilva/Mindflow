// src/main/java/br/com/mindflow/messaging/ConsultaEventListener.java
// ÚNICA mudança: injetar NotificacaoSseService e chamar .enviar() após cada .notificar()
// Filas, eventos, payloads — TUDO igual ao que você já tem.

package br.com.mindflow.messaging;

import br.com.mindflow.services.NotificacaoService;
import br.com.mindflow.services.NotificacaoSseService;   // ← NOVO import
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.core.Message;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

import com.fasterxml.jackson.databind.ObjectMapper;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@Slf4j
@Component
@RequiredArgsConstructor
public class ConsultaEventListener {

    private final ObjectMapper objectMapper;
    private final NotificacaoService    notificacaoService; 
    private final NotificacaoSseService sseService;         

    // ── Fila: consulta.solicitada → notifica PSICÓLOGO ───────────────────

    @RabbitListener(queues = Eventos.CONSULTA_SOLICITADA)
    public void onConsultaSolicitada(Message message) {
        try {
            var event = objectMapper.readValue(
                    message.getBody(), ConsultaEvent.class);

            log.info("[{}] Nova consulta | paciente: {} | psicólogo: {} | data: {}",
                    Eventos.CONSULTA_SOLICITADA,
                    event.nomePaciente(),
                    event.nomePsicologo(),
                    event.dataHora());

            String titulo = "Nova solicitação de consulta";
            String corpo  = String.format("%s solicitou uma consulta para %s",
                    event.nomePaciente(), formatarData(event.dataHora()));

            notificacaoService.notificar(event.psicologoId(), titulo, corpo); 
            sseService.enviar(event.psicologoId(), titulo, corpo, event);    

        } catch (Exception e) {
            log.error("[{}] Erro ao processar: {}",
                    Eventos.CONSULTA_SOLICITADA, e.getMessage());
        }
    }

    // ── Fila: consulta.confirmada → notifica PACIENTE ────────────────────

    @RabbitListener(queues = Eventos.CONSULTA_CONFIRMADA)
    public void onConsultaConfirmada(Message message) {
        try {
            var event = objectMapper.readValue(
                    message.getBody(), ConsultaEvent.class);

            log.info("[{}] Consulta confirmada | paciente: {} | data: {}",
                    Eventos.CONSULTA_CONFIRMADA,
                    event.nomePaciente(),
                    event.dataHora());

            String titulo = "Consulta confirmada! ✅";
            String corpo  = String.format("Sua consulta com %s foi confirmada para %s",
                    event.nomePsicologo(), formatarData(event.dataHora()));

            notificacaoService.notificar(event.pacienteId(), titulo, corpo); 
            sseService.enviar(event.pacienteId(), titulo, corpo, event);     

        } catch (Exception e) {
            log.error("[{}] Erro: {}", Eventos.CONSULTA_CONFIRMADA, e.getMessage());
        }
    }

    // ── Fila: consulta.recusada → notifica PACIENTE ──────────────────────

    @RabbitListener(queues = Eventos.CONSULTA_RECUSADA)
    public void onConsultaRecusada(Message message) {
        try {
            var event = objectMapper.readValue(
                    message.getBody(), ConsultaEvent.class);

            log.info("[{}] Consulta recusada | paciente: {}",
                    Eventos.CONSULTA_RECUSADA,
                    event.nomePaciente());

            String titulo = "Consulta não disponível";
            String corpo  = String.format(
                    "%s não pôde aceitar sua solicitação para %s. Tente outro horário.",
                    event.nomePsicologo(), formatarData(event.dataHora()));

            notificacaoService.notificar(event.pacienteId(), titulo, corpo); 
            sseService.enviar(event.pacienteId(), titulo, corpo, event);     

        } catch (Exception e) {
            log.error("[{}] Erro: {}", Eventos.CONSULTA_RECUSADA, e.getMessage());
        }
    }

    // ── Fila: consulta.cancelada → notifica PACIENTE e PSICÓLOGO ─────────

    @RabbitListener(queues = Eventos.CONSULTA_CANCELADA)
    public void onConsultaCancelada(Message message) {
        try {
            var event = objectMapper.readValue(
                    message.getBody(), ConsultaEvent.class);

            log.info("[{}] Consulta cancelada | consultaId: {}",
                    Eventos.CONSULTA_CANCELADA,
                    event.consultaId());

            // Paciente
            String tituloPac = "Consulta cancelada";
            String corpoPac  = String.format("Sua consulta de %s foi cancelada",
                    formatarData(event.dataHora()));

            notificacaoService.notificar(event.pacienteId(), tituloPac, corpoPac); 
            sseService.enviar(event.pacienteId(), tituloPac, corpoPac, event);    

            // Psicólogo
            String tituloPsi = "Consulta cancelada";
            String corpoPsi  = String.format("A consulta com %s em %s foi cancelada",
                    event.nomePaciente(), formatarData(event.dataHora()));

            notificacaoService.notificar(event.psicologoId(), tituloPsi, corpoPsi); 
            sseService.enviar(event.psicologoId(), tituloPsi, corpoPsi, event);    

        } catch (Exception e) {
            log.error("[{}] Erro: {}", Eventos.CONSULTA_CANCELADA, e.getMessage());
        }
    }


    private String formatarData(String dataHora) {
        try {
            var dt = LocalDateTime.parse(dataHora);
            return dt.format(DateTimeFormatter.ofPattern("dd/MM/yyyy 'às' HH:mm"));
        } catch (Exception e) {
            return dataHora;
        }
    }
}
package br.com.mindflow.dto.disponibilidade;

import br.com.mindflow.entity.BloqueioAgenda;
import java.time.LocalDate;
import java.util.UUID;

public record BloqueioAgendaResponse(UUID id, LocalDate data, String motivo) {
    public static BloqueioAgendaResponse from(BloqueioAgenda b) {
        return new BloqueioAgendaResponse(b.getId(), b.getData(), b.getMotivo());
    }
}

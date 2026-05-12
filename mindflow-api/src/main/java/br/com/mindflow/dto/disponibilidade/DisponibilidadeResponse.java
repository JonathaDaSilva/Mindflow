package br.com.mindflow.dto.disponibilidade;

import java.time.LocalTime;
import java.util.UUID;
import br.com.mindflow.entity.Disponibilidade;

public record DisponibilidadeResponse(
    UUID id,
    Integer diaSemana,
    String diaSemanaLabel,  
    LocalTime horaInicio,
    LocalTime horaFim
) {
    private static final String[] DIAS = {
        "", "Segunda-feira", "Terça-feira", "Quarta-feira",
        "Quinta-feira", "Sexta-feira", "Sábado", "Domingo"
    };

    public static DisponibilidadeResponse from(Disponibilidade d) {
        return new DisponibilidadeResponse(
            d.getId(), d.getDiaSemana(),
            DIAS[d.getDiaSemana()],
            d.getHoraInicio(), d.getHoraFim()
        );
    }
}
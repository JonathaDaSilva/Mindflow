package br.com.mindflow.dto.disponibilidade;

import java.time.LocalTime;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public record DisponibilidadeRequest(
    @NotNull @Min(1) @Max(7) Integer diaSemana,  
    @NotNull LocalTime horaInicio,
    @NotNull LocalTime horaFim
) {}
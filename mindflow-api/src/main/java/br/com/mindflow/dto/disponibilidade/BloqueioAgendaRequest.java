package br.com.mindflow.dto.disponibilidade;

import jakarta.validation.constraints.FutureOrPresent;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

public record BloqueioAgendaRequest(
    @NotNull @FutureOrPresent LocalDate data,
    String motivo
) {}

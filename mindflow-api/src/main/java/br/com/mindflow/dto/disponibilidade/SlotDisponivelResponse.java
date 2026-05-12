package br.com.mindflow.dto.disponibilidade;

import java.time.LocalDateTime;

public record SlotDisponivelResponse(
    LocalDateTime dataHora,
    String horaFormatada   // "14:00"
) {}
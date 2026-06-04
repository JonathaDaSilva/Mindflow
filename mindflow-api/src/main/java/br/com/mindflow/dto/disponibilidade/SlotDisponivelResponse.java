package br.com.mindflow.dto.disponibilidade;

import java.time.LocalDateTime;
import com.fasterxml.jackson.annotation.JsonFormat;

public record SlotDisponivelResponse(
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss")
    LocalDateTime dataHora,
    String horaFormatada   // "14:00"
) {}
package br.com.mindflow.dto.avaliacao;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record AvaliacaoRequest(

    @NotNull(message = "Informe uma nota de 1 a 5")
    @Min(value = 1, message = "A nota mínima é 1")
    @Max(value = 5, message = "A nota máxima é 5")
    Integer nota,

    @Size(max = 500, message = "Comentário deve ter no máximo 500 caracteres")
    String comentario

) {}

package br.com.mindflow.dto.consulta;

import java.time.LocalDateTime;
import java.util.UUID;
import br.com.mindflow.entity.enums.FormaPagamento;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import com.fasterxml.jackson.annotation.JsonFormat;

public record ConsultaRequest(
    @NotNull UUID psicologoId,
    @NotNull
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss")
    LocalDateTime dataHora,
    FormaPagamento formaPagamento,
    @Size(max = 500) String observacao
) {}
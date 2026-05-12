package br.com.mindflow.dto.consulta;

import java.time.LocalDateTime;
import java.util.UUID;
import br.com.mindflow.entity.enums.FormaPagamento;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record ConsultaRequest(
    @NotNull UUID psicologoId,
    @NotNull LocalDateTime dataHora,
    FormaPagamento formaPagamento,
    @Size(max = 500) String observacao
) {}
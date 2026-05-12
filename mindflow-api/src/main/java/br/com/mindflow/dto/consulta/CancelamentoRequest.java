package br.com.mindflow.dto.consulta;

import jakarta.validation.constraints.NotBlank;

public record CancelamentoRequest(
    @NotBlank String motivo
) {}
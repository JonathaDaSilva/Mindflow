package br.com.mindflow.dto.consulta;

import jakarta.validation.constraints.NotNull;
import br.com.mindflow.entity.enums.StatusConsulta;

public record StatusUpdateRequest(
    @NotNull StatusConsulta status
) {}
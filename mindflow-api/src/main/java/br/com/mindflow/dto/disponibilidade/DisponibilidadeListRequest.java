package br.com.mindflow.dto.disponibilidade;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import java.util.List;

public record DisponibilidadeListRequest(
    @NotNull @NotEmpty
    List<@Valid DisponibilidadeRequest> disponibilidades
) {}
package br.com.mindflow.dto.auth;

import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import br.com.mindflow.entity.enums.RegimeTrabalho;
import br.com.mindflow.dto.endereco.*;

public record DadosPsicologoRequest(
    @NotBlank String crp,
    String especialidade,
    @Size(max = 500) String bio,
    @NotNull RegimeTrabalho regimeTrabalho,
    @NotNull Integer duracaoSessaoMin,
    @NotNull BigDecimal valorSessao,
    Boolean aceitaEmergencia,
    EnderecoRequest endereco
) {}

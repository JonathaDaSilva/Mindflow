package br.com.mindflow.dto.psicologo;

import java.math.BigDecimal;
import br.com.mindflow.dto.endereco.EnderecoRequest;
import br.com.mindflow.entity.enums.RegimeTrabalho;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record PsicologoPerfilRequest(
    @NotBlank String crp,
    String especialidade,
    @Size(max = 500) String bio,
    @NotNull RegimeTrabalho regimeTrabalho,
    @NotNull Integer duracaoSessaoMin,
    @NotNull BigDecimal valorSessao,
    Boolean aceitaEmergencia,
    EnderecoRequest endereco
) {}
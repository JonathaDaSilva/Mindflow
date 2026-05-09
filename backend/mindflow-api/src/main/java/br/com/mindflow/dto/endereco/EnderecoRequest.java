package br.com.mindflow.dto.endereco;

import jakarta.validation.constraints.Pattern;

public record EnderecoRequest(
    String logradouro,
    String numero,
    String bairro,
    String cidade,
    String estado,
    @Pattern(regexp = "\\d{5}-\\d{3}") String cep
) {}
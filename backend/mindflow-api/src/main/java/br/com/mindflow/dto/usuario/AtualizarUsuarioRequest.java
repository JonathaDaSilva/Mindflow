package br.com.mindflow.dto.usuario;

import jakarta.validation.constraints.NotBlank;
public record AtualizarUsuarioRequest(
    @NotBlank
    String nome
) {}

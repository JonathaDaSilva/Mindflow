package br.com.mindflow.dto.auth;

import br.com.mindflow.entity.enums.PerfilUsuario;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record RegisterRequest(
    @NotBlank String nome,
    @Email @NotBlank String email,
    @NotBlank @Size(min = 6) String senha,
    @NotNull PerfilUsuario perfil
) {}

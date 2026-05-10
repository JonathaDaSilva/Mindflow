package br.com.mindflow.dto.auth;

import java.util.UUID;

public record AuthResponse(
    String token,
    UUID   userId,
    String nome,
    String email,
    String perfil
) {}


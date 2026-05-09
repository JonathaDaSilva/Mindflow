package br.com.mindflow.dto.usuario;

import java.time.LocalDateTime;
import java.util.UUID;
import br.com.mindflow.entity.Usuario;

public record UsuarioResponse(
    UUID   id,
    String nome,
    String email,
    String perfil,
    LocalDateTime criadoEm
) {
    public static UsuarioResponse from(Usuario u) {
        return new UsuarioResponse(
            u.getId(), u.getNome(), u.getEmail(),
            u.getPerfil().name(), u.getCriadoEm());
    }
}
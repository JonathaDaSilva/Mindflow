package br.com.mindflow.dto.paciente;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;
import br.com.mindflow.entity.PacientePerfil;
import com.fasterxml.jackson.annotation.JsonFormat;

public record PacientePerfilResponse(

    UUID   id,
    String nome,
    String email,
    String telefone,
    LocalDate dataNascimento,
    String formaPagamentoPref,
    String observacoesSaude,
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss")
    LocalDateTime criadoEm

) {
    // factory com observações — uso do próprio paciente
    public static PacientePerfilResponse from(PacientePerfil p) {
        return new PacientePerfilResponse(
            p.getId(),
            p.getUsuario().getNome(),
            p.getUsuario().getEmail(),
            p.getTelefone(),
            p.getDataNascimento(),
            p.getFormaPagamentoPref() == null ? null
                : p.getFormaPagamentoPref().name(),
            p.getObservacoesSaude(),  
            p.getCriadoEm()
        );
    }

    // factory sem observações — uso do psicólogo consultando
    public static PacientePerfilResponse fromPublico(PacientePerfil p) {
        return new PacientePerfilResponse(
            p.getId(),
            p.getUsuario().getNome(),
            p.getUsuario().getEmail(),
            p.getTelefone(),
            p.getDataNascimento(),
            p.getFormaPagamentoPref() == null ? null
                : p.getFormaPagamentoPref().name(),
            null,  
            p.getCriadoEm()
        );
    }
}

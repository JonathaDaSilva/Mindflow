package br.com.mindflow.dto.avaliacao;

import java.time.LocalDateTime;
import java.util.UUID;
import br.com.mindflow.entity.Avaliacao;
import com.fasterxml.jackson.annotation.JsonFormat;

public record AvaliacaoResponse(

    UUID id,
    UUID consultaId,
    String nomePaciente,
    String nomePsicologo,
    Integer nota,
    String comentario,

    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss")
    LocalDateTime criadoEm

) {
    public static AvaliacaoResponse from(Avaliacao a) {
        return new AvaliacaoResponse(
            a.getId(),
            a.getConsulta().getId(),
            a.getConsulta().getPaciente().getNome(),
            a.getConsulta().getPsicologo().getNome(),
            a.getNota(),
            a.getComentario(),
            a.getCriadoEm()
        );
    }
}

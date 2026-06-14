package br.com.mindflow.dto.consulta;

import java.time.LocalDateTime;
import java.util.UUID;
import br.com.mindflow.entity.Consulta;
import com.fasterxml.jackson.annotation.JsonFormat;

public record ConsultaResponse(
    UUID id,
    String nomePaciente,
    String nomePsicologo,
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss")
    LocalDateTime dataHora,
    String status,
    String formaPagamento,
    String observacao,
    String motivoCancelamento,
    String linkConsulta,
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss")
    LocalDateTime criadoEm
) {
    public static ConsultaResponse from(Consulta c) {
        return new ConsultaResponse(
            c.getId(),
            c.getPaciente().getNome(),
            c.getPsicologo().getNome(),
            c.getDataHora(),
            c.getStatus().name(),
            c.getFormaPagamento() == null ? null
                : c.getFormaPagamento().name(),
            c.getObservacao(),
            c.getMotivoCancelamento(),
            c.getLinkConsulta(),
            c.getCriadoEm()
        );
    }
}

package br.com.mindflow.dto.consulta;

import java.time.LocalDateTime;
import java.util.UUID;
import br.com.mindflow.entity.Consulta;

public record ConsultaResponse(
    UUID id,
    String nomePaciente,
    String nomePsicologo,
    LocalDateTime dataHora,
    String status,
    String formaPagamento,
    String observacao,
    String motivoCancelamento,
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
            c.getCriadoEm()
        );
    }
}

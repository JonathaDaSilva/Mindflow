package br.com.mindflow.messaging;

import java.util.UUID;

public record ConsultaEvent(
    UUID   consultaId,
    UUID   pacienteId,
    UUID   psicologoId,
    String nomePaciente,
    String nomePsicologo,
    String status,
    String dataHora,    
    String timestamp
) {}
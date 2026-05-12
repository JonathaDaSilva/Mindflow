package br.com.mindflow.repositories;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import br.com.mindflow.entity.Consulta;
import br.com.mindflow.entity.enums.StatusConsulta;

public interface ConsultaRepository extends JpaRepository<Consulta, UUID> {

    List<Consulta> findByPacienteId(UUID pacienteId);

    List<Consulta> findByPsicologoId(UUID psicologoId);

    List<Consulta> findByPsicologoIdAndStatus(
        UUID psicologoId, StatusConsulta status);

    @Query("""
        SELECT COUNT(c) > 0 FROM Consulta c
        WHERE c.psicologo.id = :psicologoId
        AND c.dataHora = :dataHora
        AND c.status NOT IN ('CANCELADA', 'RECUSADA')
        """)
    boolean existeConflito(UUID psicologoId, LocalDateTime dataHora);
}
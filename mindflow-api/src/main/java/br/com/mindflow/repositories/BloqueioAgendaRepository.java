package br.com.mindflow.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import br.com.mindflow.entity.BloqueioAgenda;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public interface BloqueioAgendaRepository extends JpaRepository<BloqueioAgenda, UUID> {

    List<BloqueioAgenda> findByPsicologoIdOrderByDataAsc(UUID psicologoId);

    boolean existsByPsicologoIdAndData(UUID psicologoId, LocalDate data);

    void deleteByPsicologoIdAndData(UUID psicologoId, LocalDate data);
}

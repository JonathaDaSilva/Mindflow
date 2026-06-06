package br.com.mindflow.repositories;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import br.com.mindflow.entity.Avaliacao;

public interface AvaliacaoRepository extends JpaRepository<Avaliacao, UUID> {

    Optional<Avaliacao> findByConsultaId(UUID consultaId);

    boolean existsByConsultaId(UUID consultaId);

    // Usado pelo psicólogo para ver suas avaliações recebidas (e futura média/reputação)
    List<Avaliacao> findByConsulta_PsicologoIdOrderByCriadoEmDesc(UUID psicologoId);
}

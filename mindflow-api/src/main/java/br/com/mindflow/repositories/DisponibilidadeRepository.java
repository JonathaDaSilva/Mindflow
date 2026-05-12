package br.com.mindflow.repositories;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import br.com.mindflow.entity.Disponibilidade;

public interface DisponibilidadeRepository extends JpaRepository<Disponibilidade, UUID> {

    List<Disponibilidade> findByPsicologoId(UUID psicologoId);

    void deleteByPsicologoId(UUID psicologoId);
}
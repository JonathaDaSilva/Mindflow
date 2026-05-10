package br.com.mindflow.repositories;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import br.com.mindflow.entity.PacientePerfil;

public interface PacientePerfilRepository extends JpaRepository<PacientePerfil, UUID> {

    Optional<PacientePerfil> findByUsuarioId(UUID usuarioId);

    boolean existsByUsuarioId(UUID usuarioId);
}
package br.com.mindflow.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import br.com.mindflow.entity.PsicologoPerfil;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import br.com.mindflow.entity.enums.RegimeTrabalho;

public interface PsicologoPerfilRepository extends JpaRepository<PsicologoPerfil, UUID> {

    Optional<PsicologoPerfil> findByUsuarioId(UUID usuarioId);

    List<PsicologoPerfil> findByAtivoTrueAndRegimeTrabalho(
        RegimeTrabalho regime
    );

    List<PsicologoPerfil> findByAtivoTrue();

    List<PsicologoPerfil> findByAtivoTrueAndAceitaEmergenciaTrue();
}
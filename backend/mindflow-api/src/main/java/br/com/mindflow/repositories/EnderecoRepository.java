package br.com.mindflow.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import br.com.mindflow.entity.Endereco;
import java.util.UUID;

public interface EnderecoRepository extends JpaRepository<Endereco, UUID> {

} 

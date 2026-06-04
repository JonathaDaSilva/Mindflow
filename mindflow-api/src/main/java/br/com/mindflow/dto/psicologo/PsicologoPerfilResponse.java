package br.com.mindflow.dto.psicologo;

import java.math.BigDecimal;
import java.util.UUID;
import br.com.mindflow.dto.endereco.EnderecoRequest;
import br.com.mindflow.entity.PsicologoPerfil;

public record PsicologoPerfilResponse(
    UUID id,
    String nome,
    String crp,
    String especialidade,
    String bio,
    String regimeTrabalho,
    Integer duracaoSessaoMin,
    BigDecimal valorSessao,
    Boolean aceitaEmergencia,
    EnderecoRequest endereco
) {
    public static PsicologoPerfilResponse from(PsicologoPerfil p) {
        EnderecoRequest end = p.getEndereco() == null ? null :
            new EnderecoRequest(
                p.getEndereco().getLogradouro(),
                p.getEndereco().getNumero(),
                p.getEndereco().getBairro(),
                p.getEndereco().getCidade(),
                p.getEndereco().getEstado(),
                p.getEndereco().getCep()
            );
        return new PsicologoPerfilResponse(
            p.getUsuario().getId(),
            p.getUsuario().getNome(),
            p.getCrp(), p.getEspecialidade(), p.getBio(),
            p.getRegimeTrabalho().name(),
            p.getDuracaoSessaoMin(), p.getValorSessao(),
            p.getAceitaEmergencia(), end
        );
    }
}

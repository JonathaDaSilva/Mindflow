package br.com.mindflow.entity;

import java.math.BigDecimal;
import java.util.UUID;

import br.com.mindflow.entity.enums.RegimeTrabalho;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "psicologo_perfis")
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class PsicologoPerfil {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @OneToOne
    @JoinColumn(name = "usuario_id", nullable = false)
    private Usuario usuario;

    private String crp;
    private String especialidade;

    @Column(length = 500)
    private String bio;

    @Enumerated(EnumType.STRING)
    private RegimeTrabalho regimeTrabalho;

    private Integer duracaoSessaoMin;

    @Column(precision = 10, scale = 2)
    private BigDecimal valorSessao;

    @Builder.Default
    private Boolean aceitaEmergencia = false;
    
    @Builder.Default
    private Boolean ativo = true;

    @OneToOne(cascade = CascadeType.ALL, orphanRemoval = true)
    @JoinColumn(name = "endereco_id")
    private Endereco endereco;
}

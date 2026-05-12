package br.com.mindflow.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import java.time.LocalDateTime;
import java.util.UUID;
import br.com.mindflow.entity.enums.*;

@Entity @Table(name = "consultas")
@Getter @Setter @Builder
@NoArgsConstructor @AllArgsConstructor
public class Consulta {

    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "paciente_id", nullable = false)
    private Usuario paciente;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "psicologo_id", nullable = false)
    private Usuario psicologo;

    @Column(name = "data_hora", nullable = false)
    private LocalDateTime dataHora;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private StatusConsulta status = StatusConsulta.SOLICITADA;

    @Enumerated(EnumType.STRING)
    private FormaPagamento formaPagamento;

    private String observacao;

    @Column(name = "motivo_cancelamento")
    private String motivoCancelamento;
    
    @CreationTimestamp
    private LocalDateTime criadoEm;

    @UpdateTimestamp
    private LocalDateTime atualizadoEm;
}
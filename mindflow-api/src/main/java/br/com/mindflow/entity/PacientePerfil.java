package br.com.mindflow.entity;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;
import br.com.mindflow.entity.enums.FormaPagamento;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "paciente_perfis")
@Getter @Setter @Builder
@NoArgsConstructor @AllArgsConstructor
public class PacientePerfil {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @OneToOne
    @JoinColumn(name = "usuario_id", nullable = false, unique = true)
    private Usuario usuario;

    private String telefone;

    private LocalDate dataNascimento;

    // preferência registrada — plataforma não processa pagamento
    @Enumerated(EnumType.STRING)
    private FormaPagamento formaPagamentoPref;

    // campo sensível LGPD — nunca retornar em listagens gerais
    @Column(name = "observacoes_saude", length = 1000)
    private String observacoesSaude;

    @CreationTimestamp
    private LocalDateTime criadoEm;

    @UpdateTimestamp
    private LocalDateTime atualizadoEm;
}

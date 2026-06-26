package br.com.mindflow.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.util.UUID;

// RF18 — psicólogo bloqueia um dia específico da agenda (ex.: férias, feriado).
// Datas bloqueadas não geram slots livres em DisponibilidadeService.buscarSlotsLivres().
@Entity @Table(name = "bloqueios_agenda")
@Getter @Setter @Builder
@NoArgsConstructor @AllArgsConstructor
public class BloqueioAgenda {

    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "psicologo_id", nullable = false)
    private Usuario psicologo;

    @Column(nullable = false)
    private LocalDate data;

    private String motivo;
}

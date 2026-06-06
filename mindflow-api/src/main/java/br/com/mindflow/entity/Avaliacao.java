package br.com.mindflow.entity;

import java.time.LocalDateTime;
import java.util.UUID;
import org.hibernate.annotations.CreationTimestamp;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

// Avaliação que o paciente atribui ao psicólogo após a conclusão da consulta (RF16).
// Vínculo 1:1 com a Consulta — cada consulta concluída pode ser avaliada uma única vez.
@Entity
@Table(name = "avaliacoes")
@Getter @Setter @Builder
@NoArgsConstructor @AllArgsConstructor
public class Avaliacao {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @OneToOne
    @JoinColumn(name = "consulta_id", nullable = false, unique = true)
    private Consulta consulta;

    @Column(nullable = false)
    private Integer nota; // 1 a 5

    @Column(length = 500)
    private String comentario;

    @CreationTimestamp
    private LocalDateTime criadoEm;
}

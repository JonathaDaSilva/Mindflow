package br.com.mindflow.dto.paciente;

import java.time.LocalDate;
import br.com.mindflow.entity.enums.FormaPagamento;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Size;

public record PacientePerfilRequest(
    String telefone,
    @Past LocalDate dataNascimento,
    FormaPagamento formaPagamentoPref,
    @Size(max = 1000) String observacoesSaude
) {}

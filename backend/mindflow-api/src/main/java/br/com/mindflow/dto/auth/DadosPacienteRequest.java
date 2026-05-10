package br.com.mindflow.dto.auth;

import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import br.com.mindflow.entity.enums.FormaPagamento;
import jakarta.validation.constraints.Past;

public record DadosPacienteRequest(
    String telefone,
    @Past LocalDate dataNascimento,
    FormaPagamento formaPagamentoPref,
    @Size(max = 1000) String observacoesSaude
) {}

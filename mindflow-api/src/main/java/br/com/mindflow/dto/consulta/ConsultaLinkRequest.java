package br.com.mindflow.dto.consulta;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ConsultaLinkRequest(

    @NotBlank(message = "Informe o link da consulta")
    @Size(max = 500, message = "Link deve ter no máximo 500 caracteres")
    String link

) {}

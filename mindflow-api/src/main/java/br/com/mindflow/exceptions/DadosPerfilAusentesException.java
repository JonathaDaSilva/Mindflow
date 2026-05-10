package br.com.mindflow.exceptions;

import org.springframework.http.HttpStatus;

public class DadosPerfilAusentesException extends AppException {
    public DadosPerfilAusentesException(String campo) {
        super(
            "Campo obrigatório ausente para o perfil: " + campo,
            HttpStatus.BAD_REQUEST
        );
    }
}
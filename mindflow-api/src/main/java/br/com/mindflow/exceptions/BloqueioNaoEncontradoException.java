package br.com.mindflow.exceptions;

import org.springframework.http.HttpStatus;

public class BloqueioNaoEncontradoException extends AppException {
    public BloqueioNaoEncontradoException() {
        super("Não há bloqueio cadastrado para esta data", HttpStatus.NOT_FOUND);
    }
}

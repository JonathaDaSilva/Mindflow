package br.com.mindflow.exceptions;

import org.springframework.http.HttpStatus;

public class AcessoNegadoException extends AppException {
    public AcessoNegadoException(String msg) {
        super(msg, HttpStatus.FORBIDDEN);
    }
}


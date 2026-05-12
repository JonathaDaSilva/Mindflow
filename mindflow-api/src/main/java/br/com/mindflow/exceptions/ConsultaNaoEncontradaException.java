package br.com.mindflow.exceptions;

import org.springframework.http.HttpStatus;

public class ConsultaNaoEncontradaException extends AppException {
    public ConsultaNaoEncontradaException() {
        super("Consulta não encontrada", HttpStatus.NOT_FOUND);
    }
}

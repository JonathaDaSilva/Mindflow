package br.com.mindflow.exceptions;

import org.springframework.http.HttpStatus;

public class ConsultaNaoConcluidaException extends AppException {
    public ConsultaNaoConcluidaException() {
        super("Só é possível avaliar consultas concluídas", HttpStatus.UNPROCESSABLE_ENTITY);
    }
}

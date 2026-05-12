package br.com.mindflow.exceptions;

import org.springframework.http.HttpStatus;

public class HorarioIndisponivelException extends AppException {
    public HorarioIndisponivelException() {
        super("Horário indisponível ou já reservado", HttpStatus.CONFLICT);
    }
}

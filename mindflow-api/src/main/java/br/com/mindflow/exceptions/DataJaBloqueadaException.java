package br.com.mindflow.exceptions;

import org.springframework.http.HttpStatus;

public class DataJaBloqueadaException extends AppException {
    public DataJaBloqueadaException() {
        super("Esta data já está bloqueada na sua agenda", HttpStatus.CONFLICT);
    }
}

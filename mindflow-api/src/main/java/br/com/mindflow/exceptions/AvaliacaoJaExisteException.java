package br.com.mindflow.exceptions;

import org.springframework.http.HttpStatus;

public class AvaliacaoJaExisteException extends AppException {
    public AvaliacaoJaExisteException() {
        super("Esta consulta já foi avaliada", HttpStatus.CONFLICT);
    }
}

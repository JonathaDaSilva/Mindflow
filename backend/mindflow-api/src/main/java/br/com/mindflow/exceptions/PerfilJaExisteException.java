package br.com.mindflow.exceptions;

import org.springframework.http.HttpStatus;

public class PerfilJaExisteException extends AppException {
    public PerfilJaExisteException() {
        super("Perfil já cadastrado", HttpStatus.CONFLICT);
    }
}

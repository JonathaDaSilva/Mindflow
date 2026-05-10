package br.com.mindflow.exceptions;

import org.springframework.http.HttpStatus;

public class PerfilNaoEncontradoException extends AppException {
    public PerfilNaoEncontradoException() {
        super("Perfil não encontrado", HttpStatus.NOT_FOUND);
    }
}

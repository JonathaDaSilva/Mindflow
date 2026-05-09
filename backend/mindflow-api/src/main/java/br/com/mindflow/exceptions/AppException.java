package br.com.mindflow.exceptions;


import org.springframework.http.HttpStatus;

public class AppException extends RuntimeException {
    private final HttpStatus status;
    public AppException(String msg, HttpStatus status) {
        super(msg); this.status = status;
    }
    public HttpStatus getStatus() { return status; }
}

public class EmailJaCadastradoException extends AppException {
    public EmailJaCadastradoException(String email) {
        super("Email já cadastrado: " + email, HttpStatus.CONFLICT);
    }
}
public class PerfilNaoEncontradoException extends AppException {
    public PerfilNaoEncontradoException() {
        super("Perfil não encontrado", HttpStatus.NOT_FOUND);
    }
}
public class PerfilJaExisteException extends AppException {
    public PerfilJaExisteException() {
        super("Perfil já cadastrado", HttpStatus.CONFLICT);
    }
}
public class AcessoNegadoException extends AppException {
    public AcessoNegadoException(String msg) {
        super(msg, HttpStatus.FORBIDDEN);
    }
}


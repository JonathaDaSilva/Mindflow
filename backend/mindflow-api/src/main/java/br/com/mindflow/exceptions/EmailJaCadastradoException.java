package br.com.mindflow.exceptions;

import org.springframework.http.HttpStatus;
public class EmailJaCadastradoException extends AppException {
    public EmailJaCadastradoException(String email) {
        super("Email já cadastrado: " + email, HttpStatus.CONFLICT);
    }
}

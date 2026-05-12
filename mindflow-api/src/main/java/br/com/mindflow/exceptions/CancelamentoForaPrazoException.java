package br.com.mindflow.exceptions;

import org.springframework.http.HttpStatus;

public class CancelamentoForaPrazoException extends AppException {
    public CancelamentoForaPrazoException(long horasRestantes) {
        super(
            "Cancelamento permitido apenas com 24h de antecedência. "
            + "Faltam apenas " + horasRestantes + "h para a consulta.",
            HttpStatus.UNPROCESSABLE_ENTITY
        );
    }
}
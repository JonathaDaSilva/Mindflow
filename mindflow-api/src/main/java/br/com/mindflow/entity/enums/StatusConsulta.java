package br.com.mindflow.entity.enums;

public enum StatusConsulta {
    SOLICITADA(1),
    EM_ANDAMENTO(2),
    CONCLUIDA(3),
    CANCELADA(4),
    NAO_COMPARECEU(6),
    COMFIRMADA(7);

    private final int valor;

    StatusConsulta(int valor) {
        this.valor = valor;
    }

    public int getValor() {
        return valor;
    }
}

package br.com.mindflow.entity.enums;

public enum RegimeTrabalho {
    PRESENCIAL(1),
    REMOTO(2),
    HIBRIDO(3);

    private final int valor;

    RegimeTrabalho(int valor) {
        this.valor = valor;
    }

    public int getValor() {
        return valor;
    }
}

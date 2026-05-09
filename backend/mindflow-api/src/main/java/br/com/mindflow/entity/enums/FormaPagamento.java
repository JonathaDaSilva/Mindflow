package br.com.mindflow.entity.enums;

public enum FormaPagamento {
    PIX(1),
    CARTAO_CREDITO(2),
    CARTAO_DEBITO(3),
    CONVENIO(4),
    DINHEIRO(5);

    private final int valor;

    FormaPagamento(int valor) {
        this.valor = valor;
    }

    public int getValor() {
        return valor;
    }
}

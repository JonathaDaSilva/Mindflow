package br.com.mindflow.entity.enums;

public enum PerfilUsuario {
    PACIENTE(1),
    PSICOLOGO(2),
    ADMIN(3);

    private final int valor;
    PerfilUsuario(int valor) {
        this.valor = valor;
    }

    public int getValor() {
        return valor;
    }
}

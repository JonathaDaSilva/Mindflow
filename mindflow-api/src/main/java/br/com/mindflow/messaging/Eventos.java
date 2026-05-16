package br.com.mindflow.messaging;

public final class Eventos {
    private Eventos() {}

    public static final String CONSULTA_SOLICITADA  = "consulta.solicitada";
    public static final String CONSULTA_CONFIRMADA  = "consulta.confirmada";
    public static final String CONSULTA_RECUSADA    = "consulta.recusada";
    public static final String CONSULTA_CANCELADA   = "consulta.cancelada";
}
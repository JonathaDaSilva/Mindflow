// Stub para Flutter Web — flutter_local_notifications não suporta web.
// Todos os métodos são no-op para que o código compile e rode no Chrome.
class NotificacaoLocalService {
  static Future<void> inicializar() async {}
  static Future<void> mostrar(String titulo, String corpo) async {}
  static Future<void> mostrarNovaSolicitacao(
      String nomePaciente, String dataHora) async {}
}

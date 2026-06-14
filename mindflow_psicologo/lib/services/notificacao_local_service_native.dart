import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificacaoLocalService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _iniciado = false;

  static Future<void> inicializar() async {
    if (_iniciado) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _iniciado = true;
  }

  static const _detalhes = NotificationDetails(
    android: AndroidNotificationDetails(
      'mindflow_consultas',
      'Consultas MindFlow',
      channelDescription: 'Notificações de novas consultas',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
  );

  static Future<void> mostrar(String titulo, String corpo) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      titulo,
      corpo,
      _detalhes,
    );
  }

  static Future<void> mostrarNovaSolicitacao(
      String nomePaciente, String dataHora) async {
    await mostrar(
      'Nova solicitação de consulta',
      '$nomePaciente solicitou uma consulta',
    );
  }
}

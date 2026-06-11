import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificacaoLocalService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _iniciado = false;

  static Future<void> inicializar() async {
    if (_iniciado) return;

    const android = AndroidInitializationSettings(
        '@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(settings);

    // Android 13+ exige solicitação em runtime — sem isso as notificações
    // são bloqueadas silenciosamente mesmo com a permissão no manifest.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _iniciado = true;
  }

  static Future<void> mostrar(String titulo, String corpo) async {
    const detalhes = NotificationDetails(
      android: AndroidNotificationDetails(
        'mindflow_paciente',
        'MindFlow Paciente',
        channelDescription: 'Atualizações das suas consultas',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      titulo,
      corpo,
      detalhes,
    );
  }
}
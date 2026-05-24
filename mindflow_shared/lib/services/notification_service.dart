import 'api_client.dart';

class NotificationService {
  static Future<void> registrarToken(String fcmToken) async {
    await ApiClient.patch(
      '/usuarios/me/fcm-token',
      {'fcmToken': fcmToken},
    );
  }
}
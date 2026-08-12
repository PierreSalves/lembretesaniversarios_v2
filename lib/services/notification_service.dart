import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> agendarLembreteDiario(String nome) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'canal_aniversarios',
      'Lembrete de Aniversários',
      channelDescription: 'Notifica sobre aniversariantes do dia',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      0,
      '🎉 Aniversariante de Hoje!',
      'Hoje é aniversário de $nome. Abra o app para enviar parabéns!',
      notificationDetails,
    );
  }
}
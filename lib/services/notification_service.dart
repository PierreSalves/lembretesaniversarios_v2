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

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);
  }

  // Agenda o lote de notificações a cada 2 horas (06:00, 08:00, 10:00, 12:00, 14:00, 16:00, 18:00, 20:00)
  static Future<void> agendarNotificacoesAniversario({
    required int idBase,
    required String nome,
    required int dia,
    required int mes,
  }) async {
    final agora = DateTime.now();
    final List<int> horasPermitidas = [6, 8, 10, 12, 14, 16, 18, 20];

    for (int i = 0; i < horasPermitidas.length; i++) {
      int hora = horasPermitidas[i];
      var dataAlvo = DateTime(agora.year, mes, dia, hora, 0);

      // Se o horário de hoje já passou, agenda para o ano seguinte
      if (dataAlvo.isBefore(agora)) {
        dataAlvo = DateTime(agora.year + 1, mes, dia, hora, 0);
      }

      final tzDataAlvo = tz.TZDateTime.from(dataAlvo, tz.local);
      int notificationId = (idBase * 100) + i;

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        '🎉 Aniversário de $nome Hoje!',
        'Lembre-se de enviar os parabéns no WhatsApp!',
        tzDataAlvo,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'canal_aniversarios',
            'Lembretes de Aniversário',
            channelDescription: 'Alertas recorrentes para dar parabéns aos colegas',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
    }
  }

  static Future<void> cancelarTodasNotificacoes() async {
    await _notificationsPlugin.cancelAll();
  }
}
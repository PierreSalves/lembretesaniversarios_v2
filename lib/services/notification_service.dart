import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Horários diurnos padrão para emissão de lembretes (08h, 12h, 16h e 20h)
  static const List<int> horariosLembrete = [8, 12, 16, 20];

  static Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notif');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(settings: initializationSettings);

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      await androidSolicitarPermissao(androidImplementation);
    }
  }

  static Future<void> androidSolicitarPermissao(
    AndroidFlutterLocalNotificationsPlugin? androidImplementation,
  ) async {
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  /// Cancela todos os agendamentos de notificações
  static Future<void> cancelarTodasNotificacoes() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Agenda lembretes nos horários estipulados para a data de aniversário
  static Future<void> agendarNotificacoesAniversario({
    required int idBase,
    required String nome,
    required int dia,
    required int mes,
  }) async {
    final agora = DateTime.now();
    final hojeInicio = DateTime(agora.year, agora.month, agora.day);

    var dataAniversario = DateTime(agora.year, mes, dia);
    if (dataAniversario.isBefore(hojeInicio)) {
      dataAniversario = DateTime(agora.year + 1, mes, dia);
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'lembretes_aniversario_channel',
          'Lembretes de Aniversários',
          channelDescription: 'Notificações de lembrete de aniversariantes',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    for (int i = 0; i < horariosLembrete.length; i++) {
      final hora = horariosLembrete[i];
      final dataNotificacao = DateTime(
        dataAniversario.year,
        dataAniversario.month,
        dataAniversario.day,
        hora,
        0,
      );

      final tzData = tz.TZDateTime.from(dataNotificacao, tz.local);

      // Só agenda se a data/hora for no futuro
      if (tzData.isAfter(tz.TZDateTime.now(tz.local))) {
        await _notificationsPlugin.zonedSchedule(
          id: idBase * 100 + i,
          title: '🎉 Aniversário Hoje!',
          body: 'Hoje é o aniversário de $nome! Lembre-se de dar os parabéns.',
          scheduledDate: tzData,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    }
  }
}

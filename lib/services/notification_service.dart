import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Inicializa o plugin de notificações e fusos horários
  static Future<void> init() async {
    // 1. Inicializa o banco de dados de fusos horários (Essencial para o zonedSchedule)
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(settings: initializationSettings);

    // 2. Solicita permissão de notificações explicitamente no Android 13+
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      await android_solicitarPermissao(androidImplementation);
    }
  }

  static Future<void> android_solicitarPermissao(
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

  /// Agenda os lembretes de 2 em 2 horas (das 06h às 20h) para a data de aniversário
  static Future<void> agendarNotificacoesAniversario({
    required int idBase,
    required String nome,
    required int dia,
    required int mes,
  }) async {
    final agora = DateTime.now();
    var dataAniversario = DateTime(agora.year, mes, dia);

    bool eHoje = (dia == agora.day && mes == agora.month);

    // Se a data deste ano já passou, agenda para o próximo ano
    if (dataAniversario.isBefore(agora) || eHoje) {
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

    // Horários para notificar: de 2h em 2h das 06:00 às 20:00
    final horarios = [6, 8, 10, 12, 14, 16, 18, 20];

    for (int i = 0; i < horarios.length; i++) {
      final hora = horarios[i];
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
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle
        );
      }
    }
  }
}

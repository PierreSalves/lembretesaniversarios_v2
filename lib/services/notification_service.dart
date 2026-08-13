import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Inicializa o plugin de notificações
  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // 📌 Parâmetro nomeado 'settings:' exigido pelas versões mais recentes
    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );
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

    // Se a data deste ano já passou, agenda para o próximo ano
    if (dataAniversario.isBefore(agora)) {
      dataAniversario = DateTime(agora.year + 1, mes, dia);
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
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

      // 📌 Parâmetros estritamente nomeados para compatibilidade com versões novas
      await _notificationsPlugin.zonedSchedule(
        id: idBase * 100 + i,
        title: '🎉 Aniversário Hoje!',
        body: 'Hoje é o aniversário de $nome! Lembre-se de dar os parabéns.',
        scheduledDate: tzData,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }
}
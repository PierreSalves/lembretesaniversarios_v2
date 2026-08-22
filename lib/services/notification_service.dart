import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/aniversariante.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'lembretes_aniversario_channel';
  static const String channelName = 'Lembretes de Aniversários';
  static const String channelDescription = 'Notificações de lembrete de aniversariantes';

  /// Horários de agendamento de 4 em 4 horas iniciando às 00:00 (total de 6 notificações no dia)
  static const List<int> horariosLembrete = [0,2,3, 4, 8, 12, 16, 20, 21, 22, 23];

  /// Inicializa o plugin de notificações, configurações de plataforma e fuso horário local
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

      if (androidImplementation != null) {
        await _criarCanalNotificacao(androidImplementation);
        await androidImplementation.requestNotificationsPermission();
      }
    }
  }

  /// Cria explicitamente o canal de notificação com prioridade máxima e som no Android
  static Future<void> _criarCanalNotificacao(
    AndroidFlutterLocalNotificationsPlugin androidImplementation,
  ) async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await androidImplementation.createNotificationChannel(channel);
  }

  /// Cria os detalhes de configuração da notificação no Android
  static NotificationDetails _obterNotificationDetails() {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@drawable/ic_notif',
        );

    return const NotificationDetails(android: androidDetails);
  }

  /// Cancela todos os agendamentos de notificações no dispositivo
  static Future<void> cancelarTodasNotificacoes() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Cancela os 6 alarmes específicos associados ao ID de um aniversariante
  static Future<void> cancelarNotificacoesDoAniversariante(int idBase) async {
    for (int i = 0; i < horariosLembrete.length; i++) {
      final int notificationId = idBase * 100 + i;
      await _notificationsPlugin.cancel(id: notificationId);
    }
  }

  /// Agenda as 6 notificações no dia do aniversário de uma pessoa
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

    final notificationDetails = _obterNotificationDetails();

    for (int i = 0; i < horariosLembrete.length; i++) {
      final hora = horariosLembrete[i];
      final tzData = tz.TZDateTime(
        tz.local,
        dataAniversario.year,
        dataAniversario.month,
        dataAniversario.day,
        hora,
        0,
      );

      // Agenda apenas se o horário for futuro
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

  /// Atualiza pontualmente os alarmes de um aniversariante com a regra dos 30 dias:
  /// Cancela alarmes anteriores e, se o aniversário estiver nos próximos 30 dias, agenda as 6 notificações
  static Future<void> atualizarNotificacaoAniversariante(
    Aniversariante aniversariante,
  ) async {
    if (aniversariante.id == null) return;

    await cancelarNotificacoesDoAniversariante(aniversariante.id!);

    if (aniversariante.diasAteProximoAniversario <= 30) {
      await agendarNotificacoesAniversario(
        idBase: aniversariante.id!,
        nome: aniversariante.nome,
        dia: aniversariante.dia,
        mes: aniversariante.mes,
      );
    }
  }

  /// Dispara uma notificação imediata de teste para validação de som e pop-up
  static Future<void> enviarNotificacaoTeste() async {
    final notificationDetails = _obterNotificationDetails();
    await _notificationsPlugin.show(
      id: 999999,
      title: '🎉 Teste de Notificação',
      body: 'As notificações estão funcionando perfeitamente no seu aparelho!',
      notificationDetails: notificationDetails,
    );
  }
}

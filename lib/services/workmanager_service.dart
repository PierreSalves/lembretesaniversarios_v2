import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';
import '../repositories/aniversariante_repository.dart';

const String taskSincronizarNotificacoes = "sincronizarNotificacoes30Dias";
const String uniqueWorkName = "periodicSyncAniversarios24h";

/// Calcula o tempo de espera até o próximo horário de madrugada desejado (padrão: 03:00 da manhã)
Duration calcularDelayParaProximaMadrugada({int horaAlvo = 3}) {
  final agora = DateTime.now();
  var proximaMadrugada = DateTime(
    agora.year,
    agora.month,
    agora.day,
    horaAlvo,
    0,
    0,
  );

  if (proximaMadrugada.isBefore(agora)) {
    proximaMadrugada = proximaMadrugada.add(const Duration(days: 1));
  }

  return proximaMadrugada.difference(agora);
}

/// Executa a varredura e agendamento dos aniversariantes dos próximos 30 dias
Future<bool> executarVarreduraEAgendamento30Dias() async {
  try {
    debugPrint("🛠️ WorkManager: Iniciando varredura de aniversariantes (30 dias)...");

    await NotificationService.init();
    await NotificationService.cancelarTodasNotificacoes();

    final lista = await AniversarianteRepository.obterTodos();
    int agendados = 0;

    for (var pessoa in lista) {
      if (pessoa.diasAteProximoAniversario <= 30 && pessoa.id != null) {
        await NotificationService.agendarNotificacoesAniversario(
          idBase: pessoa.id!,
          nome: pessoa.nome,
          dia: pessoa.dia,
          mes: pessoa.mes,
        );
        agendados++;
      }
    }

    debugPrint("✅ WorkManager: $agendados aniversariantes agendados para os próximos 30 dias!");
    return true;
  } catch (e) {
    debugPrint("❌ WorkManager: Erro ao agendar notificações: $e");
    return false;
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == taskSincronizarNotificacoes) {
      return await executarVarreduraEAgendamento30Dias();
    }
    return true;
  });
}

class WorkmanagerService {
  /// Inicializa o WorkManager, agenda os registros existentes imediatamente e registra o job periódico de 24h
  static Future<void> inicializar() async {
    try {
      await Workmanager().initialize(callbackDispatcher);

      // Garante que todos os aniversariantes já salvos no banco sejam agendados imediatamente na abertura
      await executarVarreduraEAgendamento30Dias();

      final delayInicial = calcularDelayParaProximaMadrugada(horaAlvo: 3);

      await Workmanager().registerPeriodicTask(
        uniqueWorkName,
        taskSincronizarNotificacoes,
        frequency: const Duration(hours: 24),
        initialDelay: delayInicial,
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        constraints: Constraints(
          networkType: NetworkType.notRequired,
        ),
      );

      debugPrint(
        "⏰ WorkManager configurado! Primeira execução noturna em ${delayInicial.inHours}h ${delayInicial.inMinutes % 60}m (03:00 da madrugada) e repetição a cada 24h.",
      );
    } catch (e) {
      debugPrint("❌ Erro ao inicializar WorkManager: $e");
    }
  }
}

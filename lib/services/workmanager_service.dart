import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';
import '../repositories/aniversariante_repository.dart';

const String taskSincronizarNotificacoes = "sincronizarNotificacoes30Dias";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == taskSincronizarNotificacoes) {
      try {
        debugPrint("🛠️ WorkManager: A iniciar varredura de aniversários...");

        await NotificationService.init();
        await NotificationService.cancelarTodasNotificacoes();

        final lista = await AniversarianteRepository.obterTodos();
        int agendadosComSucesso = 0;

        for (var pessoa in lista) {
          // Agenda se o aniversário ocorrer nos próximos 30 dias
          if (pessoa.diasAteProximoAniversario <= 30 && pessoa.id != null) {
            await NotificationService.agendarNotificacoesAniversario(
              idBase: pessoa.id!,
              nome: pessoa.nome,
              dia: pessoa.dia,
              mes: pessoa.mes,
            );
            agendadosComSucesso++;
          }
        }

        debugPrint(
          "✅ WorkManager: $agendadosComSucesso aniversariantes agendados para os próximos 30 dias!",
        );
        return Future.value(true);
      } catch (e) {
        debugPrint("❌ Erro na execução da Task do WorkManager: $e");
        return Future.value(false);
      }
    }
    return Future.value(true);
  });
}

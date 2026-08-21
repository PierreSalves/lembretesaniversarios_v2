import '../database/db_helper.dart';
import '../models/aniversariante.dart';

class AniversarianteRepository {
  /// Obtém todos os aniversariantes ativos (não excluídos), ordenados por mês e dia
  static Future<List<Aniversariante>> obterTodos() async {
    final registros = await DBHelper.queryAll();
    return registros.map((map) => Aniversariante.fromMap(map)).toList();
  }

  /// Obtém apenas os aniversariantes que fazem aniversário na data de hoje
  static Future<List<Aniversariante>> obterAniversariantesDeHoje() async {
    final todos = await obterTodos();
    return todos.where((item) => item.eHoje).toList();
  }

  /// Salva um novo aniversariante ou atualiza um existente
  static Future<int> salvar(Aniversariante aniversariante) async {
    if (aniversariante.id == null) {
      return await DBHelper.insert(aniversariante.toMap());
    } else {
      return await DBHelper.update(aniversariante.toMap(), aniversariante.id!);
    }
  }

  /// Realiza a exclusão lógica (soft delete) do aniversariante
  static Future<int> excluir(int id) async {
    return await DBHelper.softDelete(id);
  }

  /// Obtém todos os registros (inclusive os marcados como excluídos) para sincronização com o Drive
  static Future<List<Aniversariante>> obterParaSincronizacao() async {
    final registros = await DBHelper.queryAllParaSincronizacao();
    return registros.map((map) => Aniversariante.fromMap(map)).toList();
  }
}

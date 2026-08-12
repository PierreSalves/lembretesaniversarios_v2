import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, 'aniversarios.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE aniversariantes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT NOT NULL,
            dia INTEGER NOT NULL,
            mes INTEGER NOT NULL,
            caminho_foto TEXT,
            mensagem_customizada TEXT
          )
        ''');
      },
    );
  }

  // Inserir novo aniversariante
  static Future<int> insert(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('aniversariantes', row);
  }

  // Atualizar aniversariante mantendo a assinatura padrão (Map + ID)
  static Future<int> update(Map<String, dynamic> row, int id) async {
    Database db = await database;
    return await db.update(
      'aniversariantes',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Listar todos os aniversariantes
  static Future<List<Map<String, dynamic>>> queryAll() async {
    Database db = await database;
    return await db.query('aniversariantes', orderBy: 'mes ASC, dia ASC');
  }

  // Deletar aniversariante por ID
  static Future<int> delete(int id) async {
    Database db = await database;
    return await db.delete('aniversariantes', where: 'id = ?', whereArgs: [id]);
  }
}
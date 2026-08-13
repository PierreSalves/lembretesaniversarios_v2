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
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE aniversariantes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nome TEXT NOT NULL,
            dia INTEGER NOT NULL,
            mes INTEGER NOT NULL,
            caminho_foto TEXT,
            drive_file_id_foto TEXT,
            mensagem_customizada TEXT,
            excluido INTEGER DEFAULT 0,
            data_atualizacao INTEGER DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try { await db.execute("ALTER TABLE aniversariantes ADD COLUMN drive_file_id_foto TEXT;"); } catch (_) {}
          try { await db.execute("ALTER TABLE aniversariantes ADD COLUMN mensagem_customizada TEXT;"); } catch (_) {}
        }
        if (oldVersion < 3) {
          try { await db.execute("ALTER TABLE aniversariantes ADD COLUMN excluido INTEGER DEFAULT 0;"); } catch (_) {}
          try { await db.execute("ALTER TABLE aniversariantes ADD COLUMN data_atualizacao INTEGER DEFAULT 0;"); } catch (_) {}
        }
      },
    );
  }

  static Future<int> insert(Map<String, dynamic> row) async {
    Database db = await database;
    row['data_atualizacao'] = DateTime.now().millisecondsSinceEpoch;
    row['excluido'] = 0;
    return await db.insert('aniversariantes', row);
  }

  static Future<int> update(Map<String, dynamic> row, int id) async {
    Database db = await database;
    row['data_atualizacao'] = DateTime.now().millisecondsSinceEpoch;
    return await db.update(
      'aniversariantes',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Exclusão Lógica (Soft Delete): Apenas marca como excluído e atualiza o timestamp
  static Future<int> softDelete(int id) async {
    Database db = await database;
    return await db.update(
      'aniversariantes',
      {
        'excluido': 1,
        'data_atualizacao': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Retorna apenas os registos ativos (não excluídos) ordenados
  static Future<List<Map<String, dynamic>>> queryAll() async {
    Database db = await database;
    return await db.query(
      'aniversariantes',
      where: 'excluido = ?',
      whereArgs: [0],
      orderBy: 'mes ASC, dia ASC',
    );
  }

  /// Retorna TUDO (incluindo excluídos) para uso exclusivo do motor de Sincronização/Merge
  static Future<List<Map<String, dynamic>>> queryAllParaSincronizacao() async {
    Database db = await database;
    return await db.query('aniversariantes');
  }
}
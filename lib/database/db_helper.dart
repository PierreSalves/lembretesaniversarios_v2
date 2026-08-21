import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
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
          try {
            await db.execute(
              "ALTER TABLE aniversariantes ADD COLUMN drive_file_id_foto TEXT;",
            );
          } catch (_) {}
          try {
            await db.execute(
              "ALTER TABLE aniversariantes ADD COLUMN mensagem_customizada TEXT;",
            );
          } catch (_) {}
        }
        if (oldVersion < 3) {
          try {
            await db.execute(
              "ALTER TABLE aniversariantes ADD COLUMN excluido INTEGER DEFAULT 0;",
            );
          } catch (_) {}
          try {
            await db.execute(
              "ALTER TABLE aniversariantes ADD COLUMN data_atualizacao INTEGER DEFAULT 0;",
            );
          } catch (_) {}
        }
      },
    );
  }

  /// Fecha as conexões do SQLite e remove o arquivo físico do banco no dispositivo
  static Future<void> fecharEApagarBanco() async {
    if (_db != null) {
      if (_db!.isOpen) {
        await _db!.close();
      }
      _db = null;
    }

    try {
      String dbPath = await getDatabasesPath();
      String path = join(dbPath, 'aniversarios.db');
      File dbFile = File(path);
      if (await dbFile.exists()) {
        await dbFile.delete();
      }
    } catch (e) {
      debugPrint("Erro ao apagar o arquivo do banco: $e");
    }
  }

  static Future<int> insert(Map<String, dynamic> row) async {
    Database db = await database;
    final Map<String, dynamic> dados = Map<String, dynamic>.from(row);
    dados['data_atualizacao'] = DateTime.now().millisecondsSinceEpoch;
    dados['excluido'] = 0;
    return await db.insert('aniversariantes', dados);
  }

  static Future<int> update(Map<String, dynamic> row, int id) async {
    Database db = await database;
    final Map<String, dynamic> dados = Map<String, dynamic>.from(row);
    dados['data_atualizacao'] = DateTime.now().millisecondsSinceEpoch;
    return await db.update(
      'aniversariantes',
      dados,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

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

  static Future<List<Map<String, dynamic>>> queryAll() async {
    Database db = await database;
    return await db.query(
      'aniversariantes',
      where: 'excluido = ?',
      whereArgs: [0],
      orderBy: 'mes ASC, dia ASC',
    );
  }

  static Future<List<Map<String, dynamic>>> queryAllParaSincronizacao() async {
    Database db = await database;
    return await db.query('aniversariantes');
  }
}

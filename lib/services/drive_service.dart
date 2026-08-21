import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'auth_service.dart';
import 'network_service.dart';
import '../database/db_helper.dart';

class DriveService {
  static const String _nomeArquivoBackup = 'lembretes_aniversarios_backup.db';
  static const String _nomeArquivoUltimaSync = 'ultima_sync.txt';

  /// Obtém o cliente autenticado do Google Drive
  static Future<drive.DriveApi?> _obterDriveApi() async {
    try {
      final GoogleSignInAccount? usuario = AuthService.usuarioAtual;
      if (usuario == null) return null;

      final authClient = await AuthService.googleSignIn.authenticatedClient();
      if (authClient == null) return null;

      return drive.DriveApi(authClient);
    } catch (e) {
      debugPrint("Erro ao autenticar no Google Drive: $e");
      return null;
    }
  }

  /// Faz o upload de uma imagem individual para a pasta privada do Drive (appDataFolder)
  static Future<String?> fazerUploadImagem(File arquivoLocal) async {
    try {
      final driveApi = await _obterDriveApi();
      if (driveApi == null) return null;

      String nomeArquivoUnico = 'foto_${DateTime.now().millisecondsSinceEpoch}.jpg';
      var media = drive.Media(arquivoLocal.openRead(), await arquivoLocal.length());

      var driveFile = drive.File()
        ..name = nomeArquivoUnico
        ..parents = ['appDataFolder'];

      var arquivoCriado = await driveApi.files.create(driveFile, uploadMedia: media);
      return arquivoCriado.id;
    } catch (e) {
      debugPrint("Erro ao enviar imagem para o Drive: $e");
      return null;
    }
  }

  /// Baixa a imagem da nuvem e salva-a permanentemente no diretório local do aparelho
  static Future<String?> baixarEPeristirImagemLocalmente(String fileId) async {
    try {
      final driveApi = await _obterDriveApi();
      if (driveApi == null) return null;

      drive.Media arquivoDrive = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final diretorioApp = await getApplicationDocumentsDirectory();
      String caminhoLocal = p.join(diretorioApp.path, 'foto_peristida_$fileId.jpg');
      var arquivoLocal = File(caminhoLocal);

      List<int> dataBytes = [];
      await for (var chunk in arquivoDrive.stream) {
        dataBytes.addAll(chunk);
      }
      await arquivoLocal.writeAsBytes(dataBytes);

      return arquivoLocal.path;
    } catch (e) {
      debugPrint("Erro ao baixar imagem do Drive: $e");
      return null;
    }
  }

  /// Envia o banco de dados SQLite local como arquivo de backup no Google Drive
  static Future<void> fazerUploadBackup() async {
    try {
      final driveApi = await _obterDriveApi();
      if (driveApi == null) return;

      var databasesPath = await getDatabasesPath();
      String path = p.join(databasesPath, 'aniversarios.db');
      var arquivoLocal = File(path);

      if (!await arquivoLocal.exists()) return;

      final listaArquivos = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_nomeArquivoBackup'",
      );

      var media = drive.Media(arquivoLocal.openRead(), await arquivoLocal.length());

      if (listaArquivos.files != null && listaArquivos.files!.isNotEmpty) {
        String fileId = listaArquivos.files!.first.id!;
        await driveApi.files.update(drive.File(), fileId, uploadMedia: media);
      } else {
        var driveFile = drive.File()
          ..name = _nomeArquivoBackup
          ..parents = ['appDataFolder'];
        await driveApi.files.create(driveFile, uploadMedia: media);
      }
    } catch (e) {
      debugPrint("Erro ao realizar upload para o Drive: $e");
    }
  }

  /// Baixa os registros do backup remoto da nuvem para memória
  static Future<List<Map<String, dynamic>>?> _baixarRegistrosRemotos(drive.DriveApi driveApi) async {
    try {
      final listaArquivos = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_nomeArquivoBackup'",
      );

      if (listaArquivos.files == null || listaArquivos.files!.isEmpty) {
        return null;
      }

      String fileId = listaArquivos.files!.first.id!;
      drive.Media arquivoDrive = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      var databasesPath = await getDatabasesPath();
      String tempPath = p.join(databasesPath, 'temp_nuvem.db');
      var arquivoTemp = File(tempPath);

      List<int> dataBytes = [];
      await for (var chunk in arquivoDrive.stream) {
        dataBytes.addAll(chunk);
      }
      await arquivoTemp.writeAsBytes(dataBytes);

      Database dbNuvem = await openDatabase(tempPath);
      List<Map<String, dynamic>> registrosNuvem = await dbNuvem.query('aniversariantes');
      await dbNuvem.close();

      if (await arquivoTemp.exists()) {
        await arquivoTemp.delete();
      }

      return registrosNuvem;
    } catch (e) {
      debugPrint("Erro ao baixar registros da nuvem: $e");
      return null;
    }
  }

  /// Executa o algoritmo de resolução de conflitos (Merge) baseado no timestamp 'data_atualizacao'
  static Future<bool> _mesclarRegistros(
    Database dbLocal,
    List<Map<String, dynamic>> registrosNuvem,
  ) async {
    List<Map<String, dynamic>> registrosLocaisAtuais = await DBHelper.queryAllParaSincronizacao();
    Map<int, Map<String, dynamic>> mapaLocais = {
      for (var reg in registrosLocaisAtuais) reg['id'] as int: reg,
    };

    bool houveAlteracoes = false;

    for (var regNuvem in registrosNuvem) {
      int idNuvem = regNuvem['id'];
      int timestampNuvem = regNuvem['data_atualizacao'] ?? 0;

      if (mapaLocais.containsKey(idNuvem)) {
        var regLocal = mapaLocais[idNuvem]!;
        int timestampLocal = regLocal['data_atualizacao'] ?? 0;

        if (timestampNuvem > timestampLocal) {
          await dbLocal.update(
            'aniversariantes',
            regNuvem,
            where: 'id = ?',
            whereArgs: [idNuvem],
          );
          houveAlteracoes = true;
        }
        mapaLocais.remove(idNuvem);
      } else {
        await dbLocal.insert('aniversariantes', regNuvem);
        houveAlteracoes = true;
      }
    }

    return mapaLocais.isNotEmpty || houveAlteracoes;
  }

  /// Envia fotos de registros locais que ainda não possuem identificador no Google Drive
  static Future<void> _sincronizarUploadFotosLocais(Database dbLocal) async {
    List<Map<String, dynamic>> registrosSemFotoNoDrive = await dbLocal.query(
      'aniversariantes',
      where: '(drive_file_id_foto IS NULL OR drive_file_id_foto = "") AND caminho_foto IS NOT NULL AND caminho_foto != "" AND excluido = 0',
    );

    for (var reg in registrosSemFotoNoDrive) {
      String caminho = reg['caminho_foto'];
      if (File(caminho).existsSync()) {
        String? idDrive = await fazerUploadImagem(File(caminho));
        if (idDrive != null) {
          await dbLocal.update(
            'aniversariantes',
            {'drive_file_id_foto': idDrive},
            where: 'id = ?',
            whereArgs: [reg['id']],
          );
        }
      }
    }
  }

  /// Baixa fotos do Google Drive para registros locais cujos arquivos ainda não existem no dispositivo
  static Future<void> _sincronizarDownloadFotosRemotas(Database dbLocal) async {
    List<Map<String, dynamic>> registrosComFotoRemota = await dbLocal.query(
      'aniversariantes',
      where: 'drive_file_id_foto IS NOT NULL AND drive_file_id_foto != "" AND excluido = 0',
    );

    for (var reg in registrosComFotoRemota) {
      String? caminhoLocal = reg['caminho_foto'];
      String driveId = reg['drive_file_id_foto'];

      bool precisaBaixar = caminhoLocal == null || caminhoLocal.isEmpty || !File(caminhoLocal).existsSync();

      if (precisaBaixar) {
        String? novoCaminhoLocal = await baixarEPeristirImagemLocalmente(driveId);
        if (novoCaminhoLocal != null) {
          await dbLocal.update(
            'aniversariantes',
            {'caminho_foto': novoCaminhoLocal},
            where: 'id = ?',
            whereArgs: [reg['id']],
          );
        }
      }
    }
  }

  /// Sincronização Inteligente Local-First: Registros primeiro, depois tratamento de mídias
  static Future<bool> sincronizarComDrive() async {
    try {
      final driveApi = await _obterDriveApi();
      if (driveApi == null) return false;

      Database dbLocal = await DBHelper.database;

      // 1. Baixa e mescla registros
      final registrosNuvem = await _baixarRegistrosRemotos(driveApi);
      if (registrosNuvem != null) {
        bool precisaUpload = await _mesclarRegistros(dbLocal, registrosNuvem);
        if (precisaUpload) {
          await fazerUploadBackup();
        }
      } else {
        await fazerUploadBackup();
      }

      // 2. Sincroniza fotos pendentes (Upload e Download)
      await _sincronizarUploadFotosLocais(dbLocal);
      await _sincronizarDownloadFotosRemotas(dbLocal);

      // 3. Atualiza backup final consolidado
      await fazerUploadBackup();
      return true;
    } catch (e) {
      debugPrint("Erro na sincronização com o Google Drive: $e");
      return false;
    }
  }

  /// Sincroniza automaticamente apenas na primeira abertura do dia
  static Future<bool> sincronizarSeNecessarioHoje() async {
    try {
      if (!await NetworkService.temConexaoInternet()) return false;

      final diretorio = await getApplicationDocumentsDirectory();
      final arquivo = File(p.join(diretorio.path, _nomeArquivoUltimaSync));

      final hojeStr = DateTime.now().toIso8601String().substring(0, 10);

      String? ultimaDataSync;
      if (await arquivo.exists()) {
        ultimaDataSync = await arquivo.readAsString();
      }

      if (ultimaDataSync != hojeStr) {
        bool sucesso = await sincronizarComDrive();
        if (sucesso) {
          await arquivo.writeAsString(hojeStr);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint("Erro ao verificar sincronização diária: $e");
      return false;
    }
  }

  /// Registra que a sincronização manual foi concluída na data de hoje
  static Future<void> marcarSincronizacaoFeitaHoje() async {
    try {
      final diretorio = await getApplicationDocumentsDirectory();
      final arquivo = File(p.join(diretorio.path, _nomeArquivoUltimaSync));
      final hojeStr = DateTime.now().toIso8601String().substring(0, 10);
      await arquivo.writeAsString(hojeStr);
    } catch (e) {
      debugPrint("Erro ao marcar sincronização: $e");
    }
  }

  /// Limpa o arquivo de controle de sincronização ao sair da conta
  static Future<void> limparControleSincronizacao() async {
    try {
      final diretorio = await getApplicationDocumentsDirectory();
      final arquivo = File(p.join(diretorio.path, _nomeArquivoUltimaSync));
      if (await arquivo.exists()) {
        await arquivo.delete();
      }
    } catch (e) {
      debugPrint("Erro ao limpar controle de sincronização: $e");
    }
  }
}
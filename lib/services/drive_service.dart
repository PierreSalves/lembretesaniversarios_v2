import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'auth_service.dart';
import '../database/db_helper.dart';

class DriveService {
  static const String _nomeArquivoBackup = 'lembretes_aniversarios_backup.db';

  static Future<drive.DriveApi?> _obterDriveApi() async {
    try {
      final GoogleSignInAccount? usuario = AuthService.usuarioAtual;
      if (usuario == null) return null;

      final authClient = await AuthService.googleSignIn.authenticatedClient();
      if (authClient == null) return null;

      return drive.DriveApi(authClient);
    } catch (e) {
      print("Erro ao autenticar no Google Drive: $e");
      return null;
    }
  }

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
        var driveFile = drive.File();
        driveFile.name = _nomeArquivoBackup;
        driveFile.parents = ['appDataFolder'];
        await driveApi.files.create(driveFile, uploadMedia: media);
      }
    } catch (e) {
      print("Erro ao realizar upload para o Drive: $e");
    }
  }

  /// Sincronização Inteligente com Merge por Timestamp e Soft Delete
  static Future<bool> sincronizarComDrive() async {
    try {
      final driveApi = await _obterDriveApi();
      if (driveApi == null) return false;

      final listaArquivos = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_nomeArquivoBackup'",
      );

      if (listaArquivos.files == null || listaArquivos.files!.isEmpty) {
        await fazerUploadBackup();
        return true;
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

      Database dbNuvens = await openDatabase(tempPath);
      List<Map<String, dynamic>> registrosNuvem = await dbNuvens.query('aniversariantes');
      await dbNuvens.close();

      if (await arquivoTemp.exists()) {
        await arquivoTemp.delete();
      }

      Database dbLocal = await DBHelper.database;
      List<Map<String, dynamic>> registrosLocais = await DBHelper.queryAllParaSincronizacao();

      Map<int, Map<String, dynamic>> mapaLocais = {
        for (var reg in registrosLocais) reg['id'] as int: reg
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

      if (mapaLocais.isNotEmpty || houveAlteracoes) {
        await fazerUploadBackup();
      }

      return true;
    } catch (e) {
      print("Erro na sincronização inteligente: $e");
      return false;
    }
  }

  static Future<String?> fazerUploadImagem(File arquivoLocal) async {
    try {
      final driveApi = await _obterDriveApi();
      if (driveApi == null) return null;

      String nomeArquivoUnico = 'foto_${DateTime.now().millisecondsSinceEpoch}.jpg';
      var media = drive.Media(arquivoLocal.openRead(), await arquivoLocal.length());

      var driveFile = drive.File();
      driveFile.name = nomeArquivoUnico;
      driveFile.parents = ['appDataFolder'];

      var arquivoCriado = await driveApi.files.create(driveFile, uploadMedia: media);
      return arquivoCriado.id;
    } catch (e) {
      print("Erro ao enviar imagem para o Drive: $e");
      return null;
    }
  }

  static Future<File?> baixarImagemDoDrive(String fileId) async {
    try {
      final driveApi = await _obterDriveApi();
      if (driveApi == null) return null;

      drive.Media arquivoDrive = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final diretorioCache = await getTemporaryDirectory();
      String caminhoLocal = p.join(diretorioCache.path, 'cache_$fileId.jpg');
      var arquivoLocal = File(caminhoLocal);

      List<int> dataBytes = [];
      await for (var chunk in arquivoDrive.stream) {
        dataBytes.addAll(chunk);
      }
      await arquivoLocal.writeAsBytes(dataBytes);

      return arquivoLocal;
    } catch (e) {
      print("Erro ao baixar imagem do Drive: $e");
      return null;
    }
  }
}
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

  /// Faz o Upload de uma imagem individual para a pasta privada do Drive (appDataFolder)
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

  /// Baixa a imagem da nuvem e salva-a permanentemente no diretório local do aparelho
  static Future<String?> baixarEPeristirImagemLocalmente(String fileId) async {
    try {
      final driveApi = await _obterDriveApi();
      if (driveApi == null) return null;

      drive.Media arquivoDrive = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // Define o diretório de documentos permanente do app no aparelho
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
      print("Erro ao baixar imagem do Drive: $e");
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

  /// Sincronização Inteligente Local-First: Registos primeiro, depois tratamento de imagens
  static Future<bool> sincronizarComDrive() async {
    try {
      final driveApi = await _obterDriveApi();
      if (driveApi == null) return false;

      // 🔴 PASSO 1: MERGE DOS REGISTOS (Prioridade Máxima)
      // Baixa o banco de dados da nuvem primeiro para garantir que a lista de aniversariantes esteja atualizada
      final listaArquivos = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_nomeArquivoBackup'",
      );

      Database dbLocal = await DBHelper.database;

      if (listaArquivos.files != null && listaArquivos.files!.isNotEmpty) {
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

        List<Map<String, dynamic>> registrosLocaisAtuais = await DBHelper.queryAllParaSincronizacao();
        Map<int, Map<String, dynamic>> mapaLocais = {
          for (var reg in registrosLocaisAtuais) reg['id'] as int: reg
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
            // Se veio da nuvem e tem ID de foto remota mas não tem caminho local, limpa o caminho provisoriamente para o Passo 2 baixar
            await dbLocal.insert('aniversariantes', regNuvem);
            houveAlteracoes = true;
          }
        }

        if (mapaLocais.isNotEmpty || houveAlteracoes) {
          await fazerUploadBackup();
        }
      } else {
        // Se não há backup na nuvem ainda, envia o estado local atual
        await fazerUploadBackup();
      }

      // 🔴 PASSO 2: SINCRONIZAÇÃO DAS IMAGENS (Após os registos estarem seguros)
      // A) Envia fotos locais novas que ainda não têm ID no Drive
      List<Map<String, dynamic>> registrosLocaisParaUploadFoto = await dbLocal.query(
        'aniversariantes',
        where: '(drive_file_id_foto IS NULL OR drive_file_id_foto = "") AND caminho_foto IS NOT NULL AND caminho_foto != "" AND excluido = 0',
      );

      for (var reg in registrosLocaisParaUploadFoto) {
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

      // B) Baixa imagens remotas cujos ficheiros físicos ainda não existem no aparelho
      List<Map<String, dynamic>> registrosLocaisParaBaixarFoto = await dbLocal.query(
        'aniversariantes',
        where: 'drive_file_id_foto IS NOT NULL AND drive_file_id_foto != "" AND excluido = 0',
      );

      for (var reg in registrosLocaisParaBaixarFoto) {
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

      // Atualiza o backup final com os caminhos locais e IDs de fotos consolidados
      await fazerUploadBackup();
      return true;
    } catch (e) {
      print("Erro na sincronização inteligente com imagens: $e");
      return false;
    }
  }
}
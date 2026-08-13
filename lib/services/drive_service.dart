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

  /// Obtém o cliente HTTP autenticado com a conta Google ativa
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

  /// Faz o Upload direto do banco de dados local atual para o Google Drive
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
        await driveApi.files.update(
          drive.File(),
          fileId,
          uploadMedia: media,
        );
        print("Backup atualizado com sucesso no Google Drive!");
      } else {
        var driveFile = drive.File();
        driveFile.name = _nomeArquivoBackup;
        driveFile.parents = ['appDataFolder'];

        await driveApi.files.create(
          driveFile,
          uploadMedia: media,
        );
        print("Primeiro backup criado com sucesso no Google Drive!");
      }
    } catch (e) {
      print("Erro ao realizar upload para o Drive: $e");
    }
  }

  /// Sincronização Local-First com Mesclagem Inteligente (Merge por Nome + Data)
  static Future<void> sincronizarComDrive() async {
    try {
      final driveApi = await _obterDriveApi();
      if (driveApi == null) return;

      // 1. Procura o backup na nuvem
      final listaArquivos = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_nomeArquivoBackup'",
      );

      // Se não existe backup na nuvem ainda, apenas enviamos o estado local atual
      if (listaArquivos.files == null || listaArquivos.files!.isEmpty) {
        await fazerUploadBackup();
        return;
      }

      // 2. Se existe, baixamos para um arquivo temporário (para não destruir o local cegamente)
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

      // 3. Abre o banco temporário da nuvem para ler os registros de lá
      Database dbNuvens = await openDatabase(tempPath);
      List<Map<String, dynamic>> registrosNuvem = await dbNuvens.query('aniversariantes');
      await dbNuvens.close();

      // 4. Pega os registros locais atuais
      List<Map<String, dynamic>> registrosLocais = await DBHelper.queryAll();

      // 5. Faz a mesclagem (Smart Merge): insere localmente o que está na nuvem e não existe localmente
      bool houveNovidadesDaNuvem = false;
      for (var regNuvem in registrosNuvem) {
        String nomeNuvem = regNuvem['nome'];
        int diaNuvem = regNuvem['dia'];
        int mesNuvem = regNuvem['mes'];

        // Verifica se já existe um registro idêntico localmente (comparando nome e data)
        bool existeLocal = registrosLocais.any((loc) =>
            loc['nome'].toString().trim().toLowerCase() == nomeNuvem.toString().trim().toLowerCase() &&
            loc['dia'] == diaNuvem &&
            loc['mes'] == mesNuvem);

        if (!existeLocal) {
          // O registro está na nuvem mas não no aparelho local -> Adiciona localmente!
          await DBHelper.insert({
            'nome': nomeNuvem,
            'dia': diaNuvem,
            'mes': mesNuvem,
            'caminho_foto': regNuvem['caminho_foto'],
            'drive_file_id_foto': regNuvem['drive_file_id_foto'],
          });
          houveNovidadesDaNuvem = true;
        }
      }

      // Limpa o arquivo temporário
      if (await arquivoTemp.exists()) {
        await arquivoTemp.delete();
      }

      // 6. Se trouxemos dados novos da nuvem, atualizamos o backup na nuvem para refletir a união completa
      if (houveNovidadesDaNuvem) {
        await fazerUploadBackup();
        print("Sincronização concluída: Novos registros da nuvem foram mesclados com sucesso!");
      } else {
        print("Sincronização concluída: Local já estava atualizado com a nuvem.");
      }
    } catch (e) {
      print("Erro durante a sincronização inteligente com o Drive: $e");
    }
  }

  /// Faz o Upload de uma imagem individual para a pasta privada do Drive
  static Future<String?> fazerUploadImagem(File arquivoLocal) async {
    try {
      final driveApi = await _obterDriveApi();
      if (driveApi == null) return null;

      String nomeArquivoUnico = 'foto_${DateTime.now().millisecondsSinceEpoch}.jpg';
      var media = drive.Media(arquivoLocal.openRead(), await arquivoLocal.length());

      var driveFile = drive.File();
      driveFile.name = nomeArquivoUnico;
      driveFile.parents = ['appDataFolder']; // Salva na pasta privada do app

      var arquivoCriado = await driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );

      print("Imagem enviada com sucesso para o Google Drive! ID: ${arquivoCriado.id}");
      return arquivoCriado.id; // Retorna o ID único da imagem na nuvem
    } catch (e) {
      print("Erro ao enviar imagem para o Drive: $e");
      return null;
    }
  }

  /// Baixa uma imagem do Google Drive sob demanda usando o fileId
  static Future<File?> baixarImagemDoDrive(String fileId) async {
    try {
      final driveApi = await _obterDriveApi();
      if (driveApi == null) return null;

      drive.Media arquivoDrive = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // Salva a imagem no diretório de cache do aparelho local
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
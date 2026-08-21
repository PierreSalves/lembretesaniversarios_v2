import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../database/db_helper.dart';
import 'drive_service.dart';

class AuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  static GoogleSignIn get googleSignIn => _googleSignIn;
  static GoogleSignInAccount? get usuarioAtual => _googleSignIn.currentUser;

  /// Inicia o fluxo interativo de login com o Google
  static Future<GoogleSignInAccount?> fazerLogin() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      debugPrint("Erro no login Google: $e");
      return null;
    }
  }

  /// Tenta restaurar silenciosamente a sessão ativa do usuário com tempo limite
  static Future<GoogleSignInAccount?> tentarLoginSilencioso() async {
    try {
      return await _googleSignIn.signInSilently().timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
    } catch (e) {
      debugPrint("Erro no login silencioso: $e");
      return null;
    }
  }

  /// Desconecta a conta Google e revoga os tokens locais
  static Future<void> fazerLogout() async {
    try {
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint("Erro no logout: $e");
    }
  }

  /// Realiza o encerramento completo da sessão: apaga o banco local, limpa cache de sincronização e desloga da conta
  static Future<void> encerrarSessaoELimparDadosLocais() async {
    try {
      await DBHelper.fecharEApagarBanco();
      await DriveService.limparControleSincronizacao();
      await fazerLogout();
    } catch (e) {
      debugPrint("Erro ao encerrar sessão e limpar dados locais: $e");
    }
  }
}

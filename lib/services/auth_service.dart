import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class AuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  static GoogleSignIn get googleSignIn => _googleSignIn;
  static GoogleSignInAccount? get usuarioAtual => _googleSignIn.currentUser;

  static Future<bool> temConexaoInternet() async {
    try {
      final resultado = await InternetAddress.lookup('google.com');
      return resultado.isNotEmpty && resultado[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<GoogleSignInAccount?> fazerLogin() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      print("Erro no login Google: $e");
      return null;
    }
  }

  static Future<GoogleSignInAccount?> tentarLoginSilencioso() async {
    try {
      // Adiciona um tempo limite de 5 segundos para não travar a abertura
      return await _googleSignIn.signInSilently().timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
    } catch (e) {
      print("Erro no login silencioso: $e");
      return null;
    }
  }

  static Future<void> fazerLogout() async {
    try {
      await _googleSignIn.signOut();
      await _googleSignIn
          .disconnect(); // Desconecta e limpa os tokens do dispositivo
    } catch (e) {
      print("Erro no logout: $e");
    }
  }
}

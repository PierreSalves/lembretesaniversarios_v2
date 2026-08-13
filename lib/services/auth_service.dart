import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.appdata',
    ],
  );

  static GoogleSignInAccount? get usuarioAtual => googleSignIn.currentUser;

  static Future<bool> temConexaoInternet() async {
    try {
      final resultado = await InternetAddress.lookup('google.com');
      return resultado.isNotEmpty && resultado[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  static Future<GoogleSignInAccount?> fazerLogin() async {
    try {
      final online = await temConexaoInternet();
      if (!online) return null;
      
      return await googleSignIn.signIn();
    } catch (erro) {
      print("Erro ao realizar login: $erro");
      return null;
    }
  }

  /// Tenta restaurar a sessão de forma silenciosa ao abrir o app
  static Future<GoogleSignInAccount?> fazerLoginSilencioso() async {
    try {
      return await googleSignIn.signInSilently(); // Corrigido para signInSilently
    } catch (erro) {
      print("Erro no login silencioso: $erro");
      return null;
    }
  }

  static Future<void> fazerLogout() async {
    try {
      await googleSignIn.signOut();
    } catch (erro) {
      print("Erro ao deslogar: $erro");
    }
  }
}
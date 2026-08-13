import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // Instância do GoogleSignIn usando a API do pacote
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.appdata',
    ],
  );

  /// Retorna o usuário logado
  static GoogleSignInAccount? get usuarioAtual => _googleSignIn.currentUser;

  /// Checa conexão com internet
  static Future<bool> temConexaoInternet() async {
    try {
      final resultado = await InternetAddress.lookup('google.com');
      return resultado.isNotEmpty && resultado[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// Tenta fazer login
  static Future<GoogleSignInAccount?> fazerLogin() async {
    try {
      final online = await temConexaoInternet();
      if (!online) return null;
      
      // Tenta autenticar
      return await _googleSignIn.signIn();
    } catch (erro) {
      print("Erro ao realizar login: $erro");
      return null;
    }
  }

  /// Tenta login silencioso
  static Future<GoogleSignInAccount?> fazerLoginSilencioso() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (erro) {
      print("Erro no login silencioso: $erro");
      return null;
    }
  }

  /// Logout
  static Future<void> fazerLogout() async {
    try {
      await _googleSignIn.disconnect();
    } catch (erro) {
      print("Erro ao deslogar: $erro");
    }
  }
}
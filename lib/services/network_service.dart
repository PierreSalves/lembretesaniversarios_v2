import 'dart:io';

class NetworkService {
  /// Verifica se há conectividade ativa com a internet realizando uma consulta DNS
  static Future<bool> temConexaoInternet() async {
    try {
      final resultado = await InternetAddress.lookup('google.com');
      return resultado.isNotEmpty && resultado[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

import 'package:share_plus/share_plus.dart';
import '../models/aniversariante.dart';

class ShareHelper {
  /// Compartilha a mensagem de aniversário formatada e anexa a foto se existir localmente
  static Future<void> compartilharParabens(Aniversariante aniversariante) async {
    final String texto = aniversariante.mensagemParabensFormatada;

    if (aniversariante.temFotoLocalValida) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(aniversariante.caminhoFoto!)],
          text: texto,
        ),
      );
    } else {
      await SharePlus.instance.share(
        ShareParams(
          text: texto,
        ),
      );
    }
  }
}

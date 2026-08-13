import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/aniversariante.dart';

class CardAniversariante extends StatelessWidget {
  final Aniversariante aniversariante;
  final VoidCallback onEdit;

  const CardAniversariante({
    super.key,
    required this.aniversariante,
    required this.onEdit,
  });

  Future<void> _compartilharWhatsapp() async {
    final String texto =
        "${aniversariante.mensagemCustomizada}\n\n- Parabéns, ${aniversariante.nome}! 🎂🎉";

    if (aniversariante.caminhoFoto != null &&
        File(aniversariante.caminhoFoto!).existsSync()) {
      await Share.shareXFiles([XFile(aniversariante.caminhoFoto!)], text: texto);
    } else {
      await Share.share(texto);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: aniversariante.caminhoFoto != null &&
                  File(aniversariante.caminhoFoto!).existsSync()
              ? FileImage(File(aniversariante.caminhoFoto!))
              : null,
          child: aniversariante.caminhoFoto == null ||
                  !File(aniversariante.caminhoFoto!).existsSync()
              ? const Icon(Icons.person)
              : null,
        ),
        title: Text(
          aniversariante.nome,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          "Data: ${aniversariante.dia.toString().padLeft(2, '0')}/${aniversariante.mes.toString().padLeft(2, '0')}",
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.share, color: Colors.green),
              onPressed: _compartilharWhatsapp,
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
          ],
        ),
      ),
    );
  }
}
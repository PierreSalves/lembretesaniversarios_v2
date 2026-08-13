import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/aniversariante.dart';

class CardAniversariante extends StatelessWidget {
  final Aniversariante aniversariante;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CardAniversariante({
    super.key,
    required this.aniversariante,
    required this.onEdit,
    required this.onDelete,
  });

  Future<void> _compartilharWhatsapp(BuildContext context) async {
    final String texto =
        "${aniversariante.mensagemCustomizada ?? 'Parabéns!'}\n\n- Parabéns, ${aniversariante.nome}! 🎂🎉";

    if (aniversariante.caminhoFoto != null &&
        aniversariante.caminhoFoto!.isNotEmpty &&
        File(aniversariante.caminhoFoto!).existsSync()) {
      await Share.shareXFiles([XFile(aniversariante.caminhoFoto!)], text: texto);
    } else {
      await Share.share(texto);
    }
  }

  @override
  Widget build(BuildContext context) {
    final temFoto = aniversariante.caminhoFoto != null &&
        aniversariante.caminhoFoto!.isNotEmpty &&
        File(aniversariante.caminhoFoto!).existsSync();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: temFoto ? FileImage(File(aniversariante.caminhoFoto!)) : null,
          child: !temFoto ? const Icon(Icons.person) : null,
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
              onPressed: () => _compartilharWhatsapp(context),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
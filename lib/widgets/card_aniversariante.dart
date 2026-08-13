import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/aniversariante.dart';
import '../services/drive_service.dart';

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
        "${aniversariante.mensagemCustomizada}\n\n- Parabéns, ${aniversariante.nome}! 🎂🎉";

    if (aniversariante.caminhoFoto != null &&
        aniversariante.caminhoFoto!.isNotEmpty &&
        File(aniversariante.caminhoFoto!).existsSync()) {
      await Share.shareXFiles([XFile(aniversariante.caminhoFoto!)], text: texto);
    } else if (aniversariante.driveFileIdFoto != null &&
        aniversariante.driveFileIdFoto!.isNotEmpty) {
      File? arquivoBaixado = await DriveService.baixarImagemDoDrive(aniversariante.driveFileIdFoto!);
      if (arquivoBaixado != null && arquivoBaixado.existsSync()) {
        await Share.shareXFiles([XFile(arquivoBaixado.path)], text: texto);
      } else {
        await Share.share(texto);
      }
    } else {
      await Share.share(texto);
    }
  }

  Widget _construirAvatar() {
    if (aniversariante.caminhoFoto != null &&
        aniversariante.caminhoFoto!.isNotEmpty &&
        File(aniversariante.caminhoFoto!).existsSync()) {
      return CircleAvatar(
        backgroundImage: FileImage(File(aniversariante.caminhoFoto!)),
      );
    }

    if (aniversariante.driveFileIdFoto != null &&
        aniversariante.driveFileIdFoto!.isNotEmpty) {
      return FutureBuilder<File?>(
        future: DriveService.baixarImagemDoDrive(aniversariante.driveFileIdFoto!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData &&
              snapshot.data != null) {
            return CircleAvatar(
              backgroundImage: FileImage(snapshot.data!),
            );
          }
          return const CircleAvatar(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }

    return const CircleAvatar(
      child: Icon(Icons.person),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: _construirAvatar(),
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
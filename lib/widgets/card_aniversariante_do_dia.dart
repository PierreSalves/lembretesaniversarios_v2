import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/aniversariante.dart';
import '../services/drive_service.dart';

class CardAniversarianteDoDia extends StatelessWidget {
  final Aniversariante aniversariante;
  final VoidCallback onEdit;

  const CardAniversarianteDoDia({
    super.key,
    required this.aniversariante,
    required this.onEdit,
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
        radius: 28,
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
              radius: 28,
              backgroundImage: FileImage(snapshot.data!),
            );
          }
          return const CircleAvatar(
            radius: 28,
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
      radius: 28,
      child: Icon(Icons.person, size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green[50],
      elevation: 4,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.green[700]!, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _construirAvatar(),
              title: Text(
                aniversariante.nome,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "Hoje! (${aniversariante.dia.toString().padLeft(2, '0')}/${aniversariante.mes.toString().padLeft(2, '0')})",
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: onEdit,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _compartilharWhatsapp(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(45),
              ),
              icon: const Icon(Icons.share),
              label: const Text(
                'ENVIAR PARABÉNS NO WHATSAPP',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }
}
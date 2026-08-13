import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/aniversariante.dart';

class CardAniversarianteDoDia extends StatelessWidget {
  final Aniversariante aniversariante;
  final VoidCallback onEdit;

  const CardAniversarianteDoDia({
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
      color: Colors.green[50],
      elevation: 4,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.green[700]!, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                radius: 30,
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
              onPressed: _compartilharWhatsapp,
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
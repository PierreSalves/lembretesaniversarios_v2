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
              leading: CircleAvatar(
                radius: 28,
                backgroundImage: temFoto ? FileImage(File(aniversariante.caminhoFoto!)) : null,
                child: !temFoto ? const Icon(Icons.person, size: 28) : null,
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
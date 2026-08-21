import 'dart:io';
import 'package:flutter/material.dart';
import '../models/aniversariante.dart';
import '../utils/share_helper.dart';

class CardAniversarianteDoDia extends StatelessWidget {
  final Aniversariante aniversariante;
  final VoidCallback onEdit;

  const CardAniversarianteDoDia({
    super.key,
    required this.aniversariante,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final temFoto = aniversariante.temFotoLocalValida;

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
                backgroundImage:
                    temFoto ? FileImage(File(aniversariante.caminhoFoto!)) : null,
                child: !temFoto ? const Icon(Icons.person, size: 28) : null,
              ),
              title: Text(
                aniversariante.nome,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              subtitle: Text("Hoje! (${aniversariante.dataFormatada})"),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                tooltip: 'Editar',
                onPressed: onEdit,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => ShareHelper.compartilharParabens(aniversariante),
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
            ),
          ],
        ),
      ),
    );
  }
}
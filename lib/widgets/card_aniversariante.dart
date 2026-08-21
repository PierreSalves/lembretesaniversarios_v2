import 'dart:io';
import 'package:flutter/material.dart';
import '../models/aniversariante.dart';
import '../utils/share_helper.dart';

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

  @override
  Widget build(BuildContext context) {
    final temFoto = aniversariante.temFotoLocalValida;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              temFoto ? FileImage(File(aniversariante.caminhoFoto!)) : null,
          child: !temFoto ? const Icon(Icons.person) : null,
        ),
        title: Text(
          aniversariante.nome,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text("Data: ${aniversariante.dataFormatada}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.share, color: Colors.green),
              tooltip: 'Compartilhar',
              onPressed: () => ShareHelper.compartilharParabens(aniversariante),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              tooltip: 'Editar',
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Excluir',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
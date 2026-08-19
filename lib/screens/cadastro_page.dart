import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../database/db_helper.dart';
import '../models/aniversariante.dart';

class CadastroPage extends StatefulWidget {
  final Aniversariante? aniversariante;

  const CadastroPage({super.key, this.aniversariante});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomeController;
  late TextEditingController _mensagemController;

  int? _diaSelecionado;
  int? _mesSelecionado;
  String? _caminhoFoto;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(
      text: widget.aniversariante?.nome ?? '',
    );
    _mensagemController = TextEditingController(
      text:
          widget.aniversariante?.mensagemCustomizada ??
          "Parabéns, meu caro guerreiro! Muita saúde, paz e felicidades neste dia especial!",
    );

    if (widget.aniversariante != null) {
      _diaSelecionado = widget.aniversariante!.dia;
      _mesSelecionado = widget.aniversariante!.mes;
      _caminhoFoto = widget.aniversariante!.caminhoFoto;
    } else {
      final hoje = DateTime.now();
      _diaSelecionado = hoje.day;
      _mesSelecionado = hoje.month;
    }
  }

  Future<void> _tirarFotoCamera() async {
    final XFile? foto = await _picker.pickImage(source: ImageSource.camera);
    if (foto != null) {
      setState(() {
        _caminhoFoto = foto.path;
      });
    }
  }

  Future<void> _escolherGaleria() async {
    final XFile? foto = await _picker.pickImage(source: ImageSource.gallery);
    if (foto != null) {
      setState(() {
        _caminhoFoto = foto.path;
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_diaSelecionado == null || _mesSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione a data do aniversário.'),
        ),
      );
      return;
    }

    try {
      final novoAniversariante = Aniversariante(
        id: widget.aniversariante?.id,
        nome: _nomeController.text.trim(),
        dia: _diaSelecionado!,
        mes: _mesSelecionado!,
        caminhoFoto: _caminhoFoto,
        driveFileIdFoto: widget.aniversariante?.driveFileIdFoto,
        mensagemCustomizada: _mensagemController.text.trim(),
      );

      if (widget.aniversariante == null) {
        await DBHelper.insert(novoAniversariante.toMap());
      } else {
        await DBHelper.update(
          novoAniversariante.toMap(),
          widget.aniversariante!.id!,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      // debugPrint("Erro ao guardar aniversariante: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar no banco de dados: $e')),
        );
      }
    }
  }

  void _selecionarData(BuildContext context) async {
    final DateTime hoje = DateTime.now();
    final DateTime? dataEscolhida = await showDatePicker(
      context: context,
      initialDate: widget.aniversariante != null
          ? DateTime(
              hoje.year,
              widget.aniversariante!.mes,
              widget.aniversariante!.dia,
            )
          : hoje,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      helpText: 'SELECIONE O DIA E MÊS',
    );

    if (dataEscolhida != null) {
      setState(() {
        _diaSelecionado = dataEscolhida.day;
        _mesSelecionado = dataEscolhida.month;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool eEdicao = widget.aniversariante != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(eEdicao ? 'Editar Aniversariante' : 'Novo Aniversariante'),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar de Pré-visualização da Foto
              Center(
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey[300],
                  backgroundImage:
                      _caminhoFoto != null && File(_caminhoFoto!).existsSync()
                      ? FileImage(File(_caminhoFoto!))
                      : null,
                  child:
                      _caminhoFoto == null || !File(_caminhoFoto!).existsSync()
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 16),

              // Botões separados lado a lado para Câmara e Galeria
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _tirarFotoCamera,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Tirar Foto'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _escolherGaleria,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galeria'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Campo de Nome
              TextFormField(
                controller: _nomeController,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'Nome do Colega',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (valor) {
                  if (valor == null || valor.isEmpty) {
                    return 'O nome é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo de Data
              InkWell(
                onTap: () => _selecionarData(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data de Aniversário',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _diaSelecionado != null && _mesSelecionado != null
                        ? "${_diaSelecionado.toString().padLeft(2, '0')} / ${_mesSelecionado.toString().padLeft(2, '0')}"
                        : 'Selecione a data',
                    style: const TextStyle(fontSize: 18, color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Campo de Mensagem
              TextFormField(
                controller: _mensagemController,
                maxLines: 3,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(
                  labelText: 'Mensagem de Parabéns (WhatsApp)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.message_outlined),
                ),
              ),
              const SizedBox(height: 24),

              // Botão Salvar / Atualizar
              ElevatedButton(
                onPressed: _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: eEdicao
                      ? Colors.orange[800]
                      : Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text(
                  eEdicao
                      ? 'ATUALIZAR ANIVERSARIANTE'
                      : 'SALVAR ANIVERSARIANTE',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

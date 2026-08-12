import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../database/db_helper.dart';
import '../models/aniversariante.dart';

class CadastroPage extends StatefulWidget {
  final Aniversariante? aniversariante; // Aceita objeto opcional para edição

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
    
    // Se for edição, preenche com os dados existentes; se for novo, carrega padrão
    _nomeController = TextEditingController(text: widget.aniversariante?.nome ?? '');
    _mensagemController = TextEditingController(
      text: widget.aniversariante?.mensagemCustomizada ??
          "Parabéns, meu caro guerreiro! Muita saúde, paz e felicidades neste dia especial!",
    );

    if (widget.aniversariante != null) {
      _diaSelecionado = widget.aniversariante!.dia;
      _mesSelecionado = widget.aniversariante!.mes;
      _caminhoFoto = widget.aniversariante!.caminhoFoto;
    }
  }

  @override
  void dispose() {
    // Libera a memória alocada pelos controllers
    _nomeController.dispose();
    _mensagemController.dispose();
    super.dispose();
  }

  // Escolher ou tirar foto
  Future<void> _selecionarFoto(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _caminhoFoto = image.path;
      });
    }
  }

  // Abrir seletor de data
  Future<void> _selecionarData() async {
    final DateTime dataInicial = _diaSelecionado != null && _mesSelecionado != null
        ? DateTime(DateTime.now().year, _mesSelecionado!, _diaSelecionado!)
        : DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dataInicial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      helpText: 'SELEÇÃO DA DATA DE ANIVERSÁRIO',
      cancelText: 'CANCELAR',
      confirmText: 'CONFIRMAR',
    );

    if (picked != null) {
      setState(() {
        _diaSelecionado = picked.day;
        _mesSelecionado = picked.month;
      });
    }
  }

  // Guardar ou Atualizar no SQLite
  Future<void> _guardar() async {
    if (_formKey.currentState!.validate()) {
      if (_diaSelecionado == null || _mesSelecionado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, selecione a data de aniversário.'),
          ),
        );
        return;
      }

      final item = Aniversariante(
        id: widget.aniversariante?.id, // Preserva o ID original em caso de edição
        nome: _nomeController.text.trim(),
        dia: _diaSelecionado!,
        mes: _mesSelecionado!,
        caminhoFoto: _caminhoFoto,
        mensagemCustomizada: _mensagemController.text.trim(),
      );

      if (widget.aniversariante == null) {
        // Novo Cadastro
        await DBHelper.insert(item.toMap());
      } else {
        // Atualização (passando o mapa e o ID)
        await DBHelper.update(item.toMap(), widget.aniversariante!.id!);
      }

      if (mounted) {
        Navigator.pop(context, true); // Retorna confirmando a alteração
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool eEdicao = widget.aniversariante != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(eEdicao ? 'Editar Aniversariante' : 'Cadastrar Aniversariante'),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- ÁREA DA FOTO ---
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _caminhoFoto != null && File(_caminhoFoto!).existsSync()
                          ? FileImage(File(_caminhoFoto!))
                          : null,
                      child: _caminhoFoto == null || !File(_caminhoFoto!).existsSync()
                          ? const Icon(
                              Icons.person,
                              size: 70,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _selecionarFoto(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Câmera'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () => _selecionarFoto(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Galeria'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- CAMPO NOME ---
              TextFormField(
                controller: _nomeController,
                style: const TextStyle(fontSize: 18),
                decoration: const InputDecoration(
                  labelText: 'Nome do Aniversariante',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, insira o nome';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- CAMPO DATA ---
              InkWell(
                onTap: _selecionarData,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data de Aniversário',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.cake_outlined),
                  ),
                  child: Text(
                    _diaSelecionado != null && _mesSelecionado != null
                        ? 'Dia ${_diaSelecionado.toString().padLeft(2, '0')} do Mês ${_mesSelecionado.toString().padLeft(2, '0')}'
                        : 'Clique para escolher o dia e mês',
                    style: TextStyle(
                      fontSize: 16,
                      color: _diaSelecionado != null
                          ? Colors.black
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // --- MENSAGEM ---
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

              // --- BOTÃO SALVAR / ATUALIZAR ---
              ElevatedButton(
                onPressed: _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: eEdicao ? Colors.orange[800] : Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text(eEdicao ? 'ATUALIZAR ANIVERSARIANTE' : 'SALVAR ANIVERSARIANTE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
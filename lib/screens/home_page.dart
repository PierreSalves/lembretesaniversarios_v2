import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/aniversariante.dart';
import '../services/notification_service.dart';
import '../widgets/card_aniversariante.dart';
import '../widgets/card_aniversariante_do_dia.dart';
import 'cadastro_page.dart';
import 'configuracoes_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Aniversariante> _lista = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _inicializarTela();
  }

  /// Executa o fluxo de inicialização respeitando o SRP
  Future<void> _inicializarTela() async {
    await _carregarDados();
    await _cancelarLembretesDiarios();
    await _agendarNotificacoes();
  }

  /// SRP 1: Busca dados do SQLite
  Future<void> _carregarDados() async {
    setState(() => _carregando = true);
    final dados = await DBHelper.queryAll();
    final lista = dados.map((item) => Aniversariante.fromMap(item)).toList();

    setState(() {
      _lista = lista;
      _carregando = false;
    });
  }

  /// SRP 2: Cancela notificações pendentes antes de reagendar
  Future<void> _cancelarLembretesDiarios() async {
    await NotificationService.cancelarTodasNotificacoes();
  }

  /// SRP 3: Agenda notificações para cada aniversariante
  Future<void> _agendarNotificacoes() async {
    for (var item in _lista) {
      if (item.id != null) {
        await NotificationService.agendarNotificacoesAniversario(
          idBase: item.id!,
          nome: item.nome,
          dia: item.dia,
          mes: item.mes,
        );
      }
    }
  }

  void _abrirCadastro([Aniversariante? item]) async {
    final alterou = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroPage(aniversariante: item),
      ),
    );

    if (alterou == true) {
      await _inicializarTela();
    }
  }

  void _abrirConfiguracoes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConfiguracoesPage(),
      ),
    ).then((_) => _inicializarTela());
  }

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final aniversariantesHoje =
        _lista.where((a) => a.dia == hoje.day && a.mes == hoje.month).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aniversariantes'),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configurações e Conta',
            onPressed: _abrirConfiguracoes,
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _lista.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum aniversariante cadastrado.\nClique no botão + para adicionar!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (aniversariantesHoje.isNotEmpty) ...[
                      const Text(
                        '🎉 Aniversariante(s) de Hoje!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...aniversariantesHoje.map(
                        (item) => CardAniversarianteDoDia(
                          aniversariante: item,
                          onEdit: () => _abrirCadastro(item),
                        ),
                      ),
                      const Divider(height: 32),
                    ],
                    const Text(
                      '📋 Todos os Aniversariantes',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ..._lista.map(
                      (item) => CardAniversariante(
                        aniversariante: item,
                        onEdit: () => _abrirCadastro(item),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _abrirCadastro(),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
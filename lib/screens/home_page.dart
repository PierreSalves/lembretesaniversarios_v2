import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/aniversariante.dart';
import '../services/auth_service.dart';
import '../services/drive_service.dart';
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

  /// Executa o fluxo de inicialização preservando a ordem segura:
  /// 1. Sincronização Local-First com o Drive (sem apagar dados locais)
  /// 2. Carregamento dos dados locais do SQLite (_carregarDados)
  /// 3. Tratamento das notificações (_cancelarLembretesDiarios e _agendarNotificacoes)
  Future<void> _inicializarTela() async {
    setState(() => _carregando = true);

    try {
      // Sincroniza de forma inteligente com o Google Drive se houver internet
      if (await AuthService.temConexaoInternet()) {
        await DriveService.sincronizarComDrive();
      }
    } catch (e) {
      debugPrint("Erro ao sincronizar com o Drive na inicialização: $e");
    }

    await _carregarDados();
    await _cancelarLembretesDiarios();
    await _agendarNotificacoes();
  }

  /// Busca dados do SQLite local (Fonte da Verdade)
  Future<void> _carregarDados() async {
    final dados = await DBHelper.queryAll();
    final lista = dados.map((item) => Aniversariante.fromMap(item)).toList();

    if (mounted) {
      setState(() {
        _lista = lista;
        _carregando = false;
      });
    }
  }

  /// Cancela notificações pendentes antes de reagendar
  Future<void> _cancelarLembretesDiarios() async {
    await NotificationService.cancelarTodasNotificacoes();
  }

  /// Agenda notificações para cada aniversariante da lista
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

  /// Exclui um aniversariante localmente e atualiza o backup no Drive
  Future<void> _deletarAniversariante(Aniversariante item) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Aniversariante'),
        content: Text('Deseja realmente excluir ${item.nome}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true && item.id != null) {
      await DBHelper.delete(item.id!);
      if (await AuthService.temConexaoInternet()) {
        await DriveService.fazerUploadBackup();
      }
      await _inicializarTela();
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
      // Se alterou ou cadastrou, envia o backup atualizado para o Google Drive
      if (await AuthService.temConexaoInternet()) {
        await DriveService.fazerUploadBackup();
      }
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
                        onDelete: () => _deletarAniversariante(item),
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
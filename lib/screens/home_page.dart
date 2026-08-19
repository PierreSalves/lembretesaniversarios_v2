import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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
    _inicializarTelaLocal();
  }

  /// Inicialização Local-First: Carrega do SQLite instantaneamente
  /// e verifica se deve fazer a sincronização automática diária em segundo plano.
  Future<void> _inicializarTelaLocal() async {
    setState(() => _carregando = true);
    await _carregarDados();

    if (mounted) {
      setState(() => _carregando = false);
    }

    _silenciarNotificacoesDeHoje();
    _verificarSincronizacaoDiariaAutomatica();
  }

  Future<void> _silenciarNotificacoesDeHoje() async {
    final hoje = DateTime.now();

    // Filtra apenas os aniversariantes do dia exato
    final aniversariantesHoje = _lista
        .where((item) => item.dia == hoje.day && item.mes == hoje.month)
        .toList();

    // Reagenda apenas os de hoje (o NotificationService cuidará de jogar para o ano que vem)
    for (var aniversariante in aniversariantesHoje) {
      if (aniversariante.id != null) {
        await NotificationService.agendarNotificacoesAniversario(
          idBase: aniversariante.id!,
          nome: aniversariante.nome,
          dia: aniversariante.dia,
          mes: aniversariante.mes,
        );
      }
    }
  }

  /// Regra: Sincroniza automaticamente apenas na primeira abertura do app no dia
  Future<void> _verificarSincronizacaoDiariaAutomatica() async {
    try {
      if (!await AuthService.temConexaoInternet()) return;

      final diretorio = await getApplicationDocumentsDirectory();
      final arquivo = File('${diretorio.path}/ultima_sync.txt');

      // Formato da data atual: "YYYY-MM-DD" (ex: "2026-06-07")
      final hojeStr = DateTime.now().toIso8601String().substring(0, 10);

      String? ultimaDataSync;
      if (await arquivo.exists()) {
        ultimaDataSync = await arquivo.readAsString();
      }

      // Se ainda não sincronizou hoje, executa a sincronização silenciosa
      if (ultimaDataSync != hojeStr) {
        bool sucesso = await DriveService.sincronizarComDrive();
        if (sucesso) {
          await arquivo.writeAsString(
            hojeStr,
          ); // Registra que já sincronizou hoje
          await _carregarDados();
          await _atualizarNotificacoes();
          // debugPrint("Sincronização automática diária concluída com sucesso.");
        }
      }
    } catch (e) {
      // debugPrint("Erro na sincronização automática diária: $e");
    }
  }

  /// Acionado manualmente quando o utilizador faz Pull-to-Refresh (arrasta para baixo)
  Future<void> _sincronizarManualmente() async {
    if (await AuthService.temConexaoInternet()) {
      bool sucesso = await DriveService.sincronizarComDrive();
      if (sucesso) {
        // Atualiza também o registo da data diária para evitar duplicar esforço
        try {
          final diretorio = await getApplicationDocumentsDirectory();
          final arquivo = File('${diretorio.path}/ultima_sync.txt');
          final hojeStr = DateTime.now().toIso8601String().substring(0, 10);
          await arquivo.writeAsString(hojeStr);
        } catch (_) {}

        await _carregarDados();
        await _atualizarNotificacoes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sincronização concluída com sucesso!'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao sincronizar com o Google Drive.'),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sem conexão à internet para sincronizar.'),
          ),
        );
      }
    }
  }

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

  Future<void> _atualizarNotificacoes() async {
    await NotificationService.cancelarTodasNotificacoes();
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

  /// Exclusão Lógica instantânea offline-first
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
      await DBHelper.softDelete(item.id!);

      if (await AuthService.temConexaoInternet()) {
        DriveService.fazerUploadBackup().catchError((_) {});
      }

      await _inicializarTelaLocal();
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
      if (await AuthService.temConexaoInternet()) {
        DriveService.fazerUploadBackup().catchError((_) {});
      }
      await _inicializarTelaLocal();
    }
  }

  void _abrirConfiguracoes() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConfiguracoesPage()),
    ).then((_) => _inicializarTelaLocal());
  }

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final aniversariantesHoje = _lista
        .where((a) => a.dia == hoje.day && a.mes == hoje.month)
        .toList();

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
          : RefreshIndicator(
              onRefresh: _sincronizarManualmente,
              child: _lista.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 200),
                        Center(
                          child: Text(
                            'Nenhum aniversariante cadastrado.\nArraste para baixo para sincronizar ou clique no +!',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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

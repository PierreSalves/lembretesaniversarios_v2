import 'package:flutter/material.dart';
import '../models/aniversariante.dart';
import '../repositories/aniversariante_repository.dart';
import '../services/drive_service.dart';
import '../services/network_service.dart';
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

  /// Inicialização Local-First: Carrega do repositório instantaneamente
  /// e dispara a sincronização diária se for a primeira abertura do dia.
  Future<void> _inicializarTelaLocal() async {
    setState(() => _carregando = true);
    await _carregarDados();

    if (mounted) {
      setState(() => _carregando = false);
    }

    _verificarSincronizacaoDiariaAutomatica();
  }

  Future<void> _verificarSincronizacaoDiariaAutomatica() async {
    final sincronizou = await DriveService.sincronizarSeNecessarioHoje();
    if (sincronizou) {
      await _carregarDados();
      await _atualizarNotificacoes();
      debugPrint("Sincronização automática diária concluída.");
    }
  }

  /// Acionado manualmente quando o usuário faz Pull-to-Refresh
  Future<void> _sincronizarManualmente() async {
    if (await NetworkService.temConexaoInternet()) {
      bool sucesso = await DriveService.sincronizarComDrive();
      if (sucesso) {
        await DriveService.marcarSincronizacaoFeitaHoje();
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
    final lista = await AniversarianteRepository.obterTodos();
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
      await AniversarianteRepository.excluir(item.id!);

      if (await NetworkService.temConexaoInternet()) {
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
      if (await NetworkService.temConexaoInternet()) {
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
    final aniversariantesHoje = _lista.where((a) => a.eHoje).toList();

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

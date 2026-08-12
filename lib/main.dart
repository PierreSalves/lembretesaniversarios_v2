import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'database/db_helper.dart';
import 'models/aniversariante.dart';
import 'screens/cadastro_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MeuApp());
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lembretes de Aniversários',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

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
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);
    final dados = await DBHelper.queryAll();
    setState(() {
      _lista = dados.map((item) => Aniversariante.fromMap(item)).toList();
      _carregando = false;
    });
  }

  // Função para compartilhar no WhatsApp
  Future<void> _compartilharWhatsapp(Aniversariante item) async {
    final String texto = "${item.mensagemCustomizada}\n\n- Parabéns, ${item.nome}! 🎂🎉";

    if (item.caminhoFoto != null && File(item.caminhoFoto!).existsSync()) {
      await Share.shareXFiles([XFile(item.caminhoFoto!)], text: texto);
    } else {
      await Share.share(texto);
    }
  }

  // Função para Deletar
  void _deletar(int id) async {
    await DBHelper.delete(id);
    _carregarDados();
  }

  // ✏️ NOVA FUNÇÃO: Abre a tela de cadastro em MODO DE EDIÇÃO
  void _editar(Aniversariante item) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CadastroPage(aniversariante: item),
      ),
    );
    if (res == true) {
      _carregarDados(); // Recarrega a lista se alterou algo
    }
  }

  @override
  Widget build(BuildContext context) {
    final hoje = DateTime.now();
    final aniversariantesHoje = _lista.where((a) => a.dia == hoje.day && a.mes == hoje.month).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aniversariantes'),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
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
                    // --- SEÇÃO: ANIVERSARIANTES DE HOJE ---
                    if (aniversariantesHoje.isNotEmpty) ...[
                      const Text(
                        '🎉 Aniversariante(s) de Hoje!',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const SizedBox(height: 8),
                      ...aniversariantesHoje.map((item) => _buildCardHoje(item)),
                      const Divider(height: 32),
                    ],

                    // --- SEÇÃO: LISTA COMPLETA ---
                    const Text(
                      '📋 Todos os Aniversariantes',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ..._lista.map((item) => _buildCardNormal(item)),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CadastroPage()),
          );
          if (res == true) _carregarDados();
        },
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Cadastrar'),
      ),
    );
  }

  // Card Especial de Hoje com ícone de lápis
  Widget _buildCardHoje(Aniversariante item) {
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
                backgroundImage: item.caminhoFoto != null ? FileImage(File(item.caminhoFoto!)) : null,
                child: item.caminhoFoto == null ? const Icon(Icons.person) : null,
              ),
              title: Text(
                item.nome,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              subtitle: Text("Hoje! (${item.dia.toString().padLeft(2, '0')}/${item.mes.toString().padLeft(2, '0')})"),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue), // ✏️ Botão Editar no Card de Hoje
                onPressed: () => _editar(item),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _compartilharWhatsapp(item),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(45),
              ),
              icon: const Icon(Icons.share),
              label: const Text('ENVIAR PARABÉNS NO WHATSAPP', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  // Card Normal com o ícone de Editar
  Widget _buildCardNormal(Aniversariante item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: item.caminhoFoto != null ? FileImage(File(item.caminhoFoto!)) : null,
          child: item.caminhoFoto == null ? const Icon(Icons.person) : null,
        ),
        title: Text(item.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text("Data: ${item.dia.toString().padLeft(2, '0')}/${item.mes.toString().padLeft(2, '0')}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.share, color: Colors.green),
              onPressed: () => _compartilharWhatsapp(item),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue), // ✏️ Botão Editar
              onPressed: () => _editar(item),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deletar(item.id!),
            ),
          ],
        ),
      ),
    );
  }
}
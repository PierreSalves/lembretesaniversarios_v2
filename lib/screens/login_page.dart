import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/drive_service.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _carregando = false;
  String _mensagemStatus = '';

  @override
  void initState() {
    super.initState();
    _verificarLoginExistente();
  }

  /// Responsabilidade 1: Verificar se existe sessão ativa (Login Silencioso)
  Future<void> _verificarLoginExistente() async {
    _atualizarStatus(carregando: true, mensagem: 'Verificando sessão...');

    final conta = await AuthService.tentarLoginSilencioso();

    if (conta != null && mounted) {
      await _sincronizarESeguir();
    } else if (mounted) {
      _atualizarStatus(carregando: false);
    }
  }

  /// Responsabilidade 2: Processar a autenticação interativa com o Google
  Future<void> _realizarLogin() async {
    final temInternet = await AuthService.temConexaoInternet();
    if (!temInternet) {
      _exibirSnackBar('Sem conexão com a internet para realizar o login.');
      return;
    }

    _atualizarStatus(
      carregando: true,
      mensagem: 'Autenticando com o Google...',
    );

    try {
      final conta = await AuthService.fazerLogin();

      if (conta != null && mounted) {
        await _sincronizarESeguir();
      } else if (mounted) {
        _atualizarStatus(carregando: false);
        _exibirSnackBar('Login cancelado pelo utilizador.');
      }
    } catch (e) {
      // debugPrint("Erro no login: $e");
      if (mounted) {
        _atualizarStatus(carregando: false);
        _exibirSnackBar('Erro ao realizar login: $e');
      }
    }
  }

  /// Responsabilidade 3: Orquestrar a sincronização do Drive antes da entrada
  Future<void> _sincronizarESeguir() async {
    _atualizarStatus(
      carregando: true,
      mensagem: 'Sincronizando dados com o Google Drive...',
    );

    try {
      if (await AuthService.temConexaoInternet()) {
        await DriveService.sincronizarComDrive();
      }
    } catch (e) {
      // debugPrint("Erro na sincronização inicial: $e");
    }

    if (mounted) {
      _navegarParaHome();
    }
  }

  /// Responsabilidade 4: Tratar a navegação de ecrãs
  void _navegarParaHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  /// Responsabilidade 5: Utilitários de Interface (UI Helpers)
  void _atualizarStatus({required bool carregando, String mensagem = ''}) {
    if (mounted) {
      setState(() {
        _carregando = carregando;
        _mensagemStatus = mensagem;
      });
    }
  }

  void _exibirSnackBar(String texto) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(texto)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.cake_rounded, size: 100, color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                'Lembretes de Aniversários',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Organize e lembre dos aniversários da sua equipe com facilidade.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[300]),
              ),
              const SizedBox(height: 48),
              if (_carregando) ...[
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  _mensagemStatus,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _realizarLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(
                    Icons.account_circle,
                    color: Colors.blue,
                    size: 28,
                  ),
                  label: const Text(
                    'Entrar com a Conta Google',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

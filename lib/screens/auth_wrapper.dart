import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import 'login_page.dart';

/// Widget responsável por checar a sessão do usuário na inicialização
/// e redirecioná-lo para a tela correta (HomePage ou LoginPage).
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _checandoSessao = true;
  bool _estaLogado = false;

  @override
  void initState() {
    super.initState();
    _verificarAutenticacao();
  }

  Future<void> _verificarAutenticacao() async {
    final conta = await AuthService.fazerLoginSilencioso();

    if (mounted) {
      setState(() {
        _estaLogado = conta != null;
        _checandoSessao = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checandoSessao) {
      return Scaffold(
        backgroundColor: Colors.blueGrey[900],
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return _estaLogado ? const HomePage() : const LoginPage();
  }
}
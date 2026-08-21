import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import 'login_page.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _verificando = true;
  bool _logado = false;

  @override
  void initState() {
    super.initState();
    _verificarSessao();
  }

  Future<void> _verificarSessao() async {
    try {
      final usuario = await AuthService.tentarLoginSilencioso();
      if (mounted) {
        setState(() {
          _logado = usuario != null;
          _verificando = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao verificar sessão: $e');
      if (mounted) {
        setState(() {
          _logado = false;
          _verificando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_verificando) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_logado) {
      return const HomePage();
    } else {
      return const LoginPage();
    }
  }
}
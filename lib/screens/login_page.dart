import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';
import 'home_page.dart'; // Importa a HomePage diretamente do seu próprio arquivo

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _carregando = false;
 
 @override
  void initState() {
    super.initState();
    _verificarLoginExistente();
  }

  /// Verifica se o usuário já fez login anteriormente no aparelho
  Future<void> _verificarLoginExistente() async {
    setState(() => _carregando = true);
    final conta = await AuthService.fazerLoginSilencioso();
    setState(() => _carregando = false);

    if (conta != null && mounted) {
      _navegarParaHome();
    }
  }
  
  /// Executa a ação do botão de Login
  Future<void> _realizarLogin() async {
    setState(() => _carregando = true);

    // 1. Verifica se o usuário tem conexão com a internet para o primeiro login
    final temInternet = await AuthService.temConexaoInternet();
    if (!temInternet) {
      setState(() => _carregando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Conexão com a internet necessária para o primeiro login com o Google.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // 2. Tenta autenticar via Google Sign-In
    final GoogleSignInAccount? conta = await AuthService.fazerLogin();
    setState(() => _carregando = false);

    if (conta != null && mounted) {
      _navegarParaHome();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível realizar o login com a conta Google.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navegarParaHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()), // Sem 'const'
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone ou Logo do Aplicativo
              const Icon(
                Icons.cake_rounded,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 24),

              // Título Principal
              const Text(
                'Aniversariantes',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              // Subtítulo descritivo
              Text(
                'Mantenha seus lembretes e cadastros sincronizados com a sua conta Google.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[300],
                ),
              ),
              const SizedBox(height: 48),

              // Indicador de Carregamento ou Botão de Login
              _carregando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : ElevatedButton.icon(
                      onPressed: _realizarLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                        height: 24,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.account_circle, color: Colors.blue),
                      ),
                      label: const Text(
                        'Entrar com a Conta Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
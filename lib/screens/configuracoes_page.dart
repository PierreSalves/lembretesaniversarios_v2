import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class ConfiguracoesPage extends StatelessWidget {
  const ConfiguracoesPage({super.key});

  /// Função para confirmar e realizar o Logout
  void _confirmarLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da Conta'),
        content: const Text(
          'Deseja realmente sair da sua conta Google?\n\n'
          'Seus dados continuarão salvos com segurança no seu Google Drive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx); // Fecha o modal
              await AuthService.fazerLogout();

              if (context.mounted) {
                // Redireciona para a tela de Login removendo todo o histórico de navegação
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            child: const Text('SAIR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = AuthService.usuarioAtual;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- SEÇÃO: INFORMAÇÕES DO USUÁRIO ---
          if (usuario != null) ...[
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: usuario.photoUrl != null
                          ? NetworkImage(usuario.photoUrl!)
                          : null,
                      child: usuario.photoUrl == null
                          ? const Icon(Icons.person, size: 35)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            usuario.displayName ?? 'Usuário',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            usuario.email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // --- SEÇÃO: APARÊNCIA E CONTA ---
          const Text(
            'Conta e Sincronização',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(Icons.cloud_done, color: Colors.green),
            title: const Text('Sincronização com o Drive'),
            subtitle: const Text('Ativa e salva automaticamente'),
          ),

          const Divider(),

          // Botão de Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Sair da Conta',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Desconecta a sua conta Google deste aparelho'),
            onTap: () => _confirmarLogout(context),
          ),

          const SizedBox(height: 32),

          // --- SEÇÃO: OPERAÇÕES FUTURAS (Espaço reservado) ---
          const Text(
            'Sobre o App',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 8),

          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Versão do Aplicativo'),
            subtitle: Text('1.0.0'),
          ),
        ],
      ),
    );
  }
}
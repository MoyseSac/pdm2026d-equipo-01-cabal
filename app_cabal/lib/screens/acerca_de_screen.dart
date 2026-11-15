import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/avisos.dart';

class AcercaDeScreen extends StatelessWidget {
  const AcercaDeScreen({super.key});

  Future<void> _abrirIcons8(BuildContext context) async {
    try {
      if (await launchUrl(Uri.parse('https://icons8.com'))) return;
    } catch (_) {
      // El credito sigue disponible si el dispositivo no tiene navegador.
    }
    if (!context.mounted) return;
    mostrarAvisoTemporal(
      context,
      contenido: const Text('Puedes visitar https://icons8.com'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de Cabal')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Créditos', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          const Text(
            'Iconos de categorías y estados vacíos por Icons8, colección Color.',
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _abrirIcons8(context),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Icons8 · icons8.com'),
            ),
          ),
        ],
      ),
    );
  }
}

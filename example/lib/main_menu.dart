import 'package:flutter/material.dart';
import 'crypto/crypto_example.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nano Examples Showcase')),
      body: ListView(
        children: [
          _buildMenuItem(
            context,
            'Live Crypto Ticker',
            'Surgical updates, computed atoms, and live streams.',
            Icons.currency_bitcoin,
            const CryptoTickerPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Widget page,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
        },
      ),
    );
  }
}

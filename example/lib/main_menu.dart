import 'package:flutter/material.dart';
import 'counter/counter_example.dart';
import 'search/search_example.dart';
import 'shopping/shopping_example.dart';

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
            'Counter & Computed',
            'Showcases Atom, ComputedAtom, and basic state updates.',
            Icons.numbers,
            const CounterPage(),
          ),
          _buildMenuItem(
            context,
            'Async Search',
            'Showcases AsyncAtom, NanoLazy, and dependency injection.',
            Icons.search,
            const SearchPage(),
          ),
          _buildMenuItem(
            context,
            'Shopping Cart',
            'Showcases complex ComputedAtom logic and interactions.',
            Icons.shopping_cart,
            const ShoppingPage(),
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
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => page),
          );
        },
      ),
    );
  }
}

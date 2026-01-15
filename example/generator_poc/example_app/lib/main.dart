import 'package:flutter/material.dart';
import 'package:nano/nano.dart';
import 'vanilla_counter.dart';
import 'classic_nano_counter.dart';
import 'poc_nano_counter.dart';

void main() {
  runApp(const MaterialApp(home: MainSelection()));
}

class MainSelection extends StatefulWidget {
  const MainSelection({super.key});

  @override
  State<MainSelection> createState() => _MainSelectionState();
}

class _MainSelectionState extends State<MainSelection> {
  int _index = 0;

  final _pages = const [
    VanillaCounter(),
    ClassicNanoCounter(),
    PocNanoCounter(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.coffee),
            label: 'Vanilla',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Classic',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_fix_high),
            label: 'PoC (Generated)',
          ),
        ],
      ),
    );
  }
}

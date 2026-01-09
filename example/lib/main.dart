import 'package:flutter/material.dart';
import 'package:nano/nano.dart';
import 'main_menu.dart';
import 'search/search_example.dart';

void main() {
  // Initialize Nano for debugging
  Nano.init();
  Nano.observer = historyObserver;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scope(
      modules: [
        NanoLazy((r) => SearchService()),
        NanoFactory((r) => SearchLogic(r.get())),
      ],
      child: MaterialApp(
        title: 'Nano Showcase',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MainMenu(),
      ),
    );
  }
}
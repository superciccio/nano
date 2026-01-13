import 'package:flutter/material.dart';
import 'package:nano/nano.dart';
import 'crypto/crypto_service.dart';
import 'main_menu.dart';

void main() {
  // Initialize Nano for debugging
  Nano.init();
  Nano.observer = _DefaultObserver(); // Reset to default for simplicity
  runApp(const MyApp());
}

// Simple internal observer re-implementation if not visible,
// or just use Nano.observer directly if we don't need history for this demo.
// For the showcase, let's stick to the default one provided by Nano.init();
class _DefaultObserver extends NanoObserver {
  @override
  void onChange(Atom atom, dynamic oldValue, dynamic newValue) {
    debugPrint(
      '?? NANO [${atom.label ?? atom.runtimeType}]: $oldValue -> $newValue',
    );
  }

  @override
  void onError(Atom atom, Object error, StackTrace stack) {
    debugPrint('?? NANO ERROR [${atom.label ?? atom.runtimeType}]: $error');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scope(
      modules: [
        // Register the CryptoService as a lazy singleton
        NanoLazy((r) => CryptoService()),
      ],
      child: MaterialApp(
        title: 'Nano Showcase',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // Dark Theme for that "Crypto" vibe
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blueAccent,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blueAccent,
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.dark, // Force Dark Mode for the showcase
        home: const MainMenu(),
      ),
    );
  }
}

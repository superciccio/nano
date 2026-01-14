import 'package:flutter/material.dart';
import 'package:nano/nano.dart';
import 'package:nano_hub/core/theme.dart';
import 'package:nano_hub/core/demo_registry.dart';
import 'package:nano_hub/features/dashboard/dashboard_view.dart';
import 'package:nano_hub/features/streams/streams_feature.dart';
import 'package:nano_hub/features/explorer/explorer_feature.dart';
import 'package:nano_hub/features/persistence/persistence_feature.dart';
import 'package:nano_hub/features/forms/forms_feature.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("?? NANO HUB: Starting...");

  // Register v0.7.0 Features
  StreamsFeature.register();
  ExplorerFeature.register();
  PersistenceFeature.register();
  FormsFeature.register();

  debugPrint(
    "?? NANO HUB: Features registered. Modules: ${DemoRegistry.modules.length}",
  );

  final prefs = await SharedPreferences.getInstance();
  final storage = SharedPrefsStorage(prefs);

  // Set global observer with custom log tag
  // This automatically handles DevTools history
  Nano.defaultObserver = const DefaultObserver(logTag: 'NANO HUB');

  final config = NanoConfig(storage: storage);

  // Run the app with the customized scope
  runApp(Scope(modules: const [], config: config, child: const NanoHubApp()));
}

class NanoHubApp extends StatelessWidget {
  const NanoHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nano Hub',
      debugShowCheckedModeBanner: false,
      theme: NanoHubTheme.darkTheme,
      home: const DashboardView(),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';
import 'package:path/path.dart' as p;

/// Records state changes within a Nano session.
class HistoryRecorder extends NanoObserver {
  final List<Map<String, dynamic>> _history = [];

  List<Map<String, dynamic>> get history => List.unmodifiable(_history);

  @override
  void onChange(Atom atom, dynamic oldValue, dynamic newValue) {
    _history.add({
      'type': 'change',
      'label': atom.label ?? atom.runtimeType.toString(),
      'old': _serialize(oldValue),
      'new': _serialize(newValue),
    });
  }

  @override
  void onError(Atom atom, Object error, StackTrace stack) {
    _history.add({
      'type': 'error',
      'label': atom.label ?? atom.runtimeType.toString(),
      'error': error.toString(),
    });
  }

  dynamic _serialize(dynamic val) {
    if (val is num || val is String || val is bool || val == null) return val;
    if (val is List) return val.map(_serialize).toList();
    if (val is Map) {
      return val.map((k, v) => MapEntry(k.toString(), _serialize(v)));
    }
    if (val is Enum) return val.toString();
    
    // Try common serialization patterns
    try {
      // ignore: avoid_dynamic_calls
      return val.toJson();
    } catch (_) {}
    
    return val.toString();
  }

  void clear() => _history.clear();

  String toJson() => const JsonEncoder.withIndent('  ').convert(_history);
}

/// A harness for managing Nano test sessions with snapshot support.
class NanoTestHarness<T extends NanoLogic> {
  final T logic;
  final HistoryRecorder recorder = HistoryRecorder();
  
  NanoTestHarness(this.logic);

  /// Records actions performed on the logic.
  Future<void> record(FutureOr<void> Function(T logic) action) async {
    await runZoned(
      () async {
        await action(logic);
        await settled();
      },
      zoneValues: {
        #nanoConfig: NanoConfig(observer: recorder),
      },
    );
  }

  /// Waits for all pending microtasks and async operations to settle.
  Future<void> settled() async {
    for (int i = 0; i < 5; i++) {
      await Future.microtask(() {});
      await Future.delayed(Duration.zero);
    }
  }

  /// Verifies that the recorded history matches a golden file.
  /// 
  /// The file is stored in `test/goldens/[name].json`.
  /// If the file doesn't exist, it will be created.
  /// To update goldens, run tests with `--dart-define=UPDATE_GOLDENS=true`.
  void expectSnapshot(String name) {
    final actualJson = recorder.toJson();
    final goldenDir = Directory(p.join(Directory.current.path, 'test', 'goldens'));
    if (!goldenDir.existsSync()) {
      goldenDir.createSync(recursive: true);
    }

    final goldenFile = File(p.join(goldenDir.path, '$name.json'));
    final shouldUpdate = const bool.fromEnvironment('UPDATE_GOLDENS', defaultValue: false);

    if (!goldenFile.existsSync() || shouldUpdate) {
      goldenFile.writeAsStringSync(actualJson);
      // ignore: avoid_print
      print('?? UPDATED GOLDEN: ${goldenFile.path}');
      return;
    }

    final expectedJson = goldenFile.readAsStringSync();
    if (actualJson != expectedJson) {
      // Use standard expect for a nice diff in IDEs
      expect(actualJson, expectedJson, reason: 'Snapshot mismatch for "$name". Run with --dart-define=UPDATE_GOLDENS=true to update.');
    }
  }
}

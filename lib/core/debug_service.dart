import 'dart:developer' as dev;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nano/core/history_observer.dart';
import 'package:nano/core/nano_core.dart';

/// Handles communication between the running app and DevTools.
class NanoDebugService {
  static final List<Atom> _registeredAtoms = [];
  static final List<NanoDerivation> _registeredDerivations = [];

  /// [Internal] Returns the number of registered atoms. Used for testing.
  @visibleForTesting
  static int get registeredAtomCount => _registeredAtoms.length;

  /// Registers an [Atom] to be visible in DevTools.
  static void registerAtom(Atom atom) {
    if (!kDebugMode) return;
    if (!_registeredAtoms.contains(atom)) {
      _registeredAtoms.add(atom);
    }
  }

  /// Unregisters an [Atom].
  static void unregisterAtom(Atom atom) {
    _registeredAtoms.remove(atom);
  }

  /// Registers a [NanoDerivation] (Computed/Reaction) to be tracked.
  static void registerDerivation(NanoDerivation derivation) {
    if (!kDebugMode) return;
    if (!_registeredDerivations.contains(derivation)) {
      _registeredDerivations.add(derivation);
    }
  }

  /// Unregisters a [NanoDerivation].
  static void unregisterDerivation(NanoDerivation derivation) {
    _registeredDerivations.remove(derivation);
  }

  static bool _initialized = false;

  /// Initializes the service extensions.
  static void init() {
    if (!kDebugMode || _initialized) return;
    _initialized = true;

    dev.registerExtension('ext.nano.getAtoms', (method, parameters) async {
      final atomsJson = _registeredAtoms.map((atom) {
        return {
          'label': atom.label ?? 'Atom',
          'value': atom.value.toString(),
          'type': atom.runtimeType.toString(),
          'state': _getAsyncState(atom),
          'meta': atom.meta.map((k, v) => MapEntry(k, v.toString())),
        };
      }).toList();

      return dev.ServiceExtensionResponse.result(
        json.encode({
          'timestamp': DateTime.now().toIso8601String(),
          'atoms': atomsJson,
        }),
      );
    });

    dev.registerExtension('ext.nano.getHistory', (method, parameters) async {
      final historyJson = historyObserver.events.map((event) {
        return {
          'label': event.label,
          'oldValue': event.oldValue.toString(),
          'newValue': event.newValue.toString(),
          'timestamp': event.timestamp.toIso8601String(),
        };
      }).toList();

      return dev.ServiceExtensionResponse.result(
        json.encode({'history': historyJson}),
      );
    });

    dev.registerExtension('ext.nano.revertToState', (method, parameters) async {
      try {
        final label = parameters['label'];
        final value = parameters['value'];
        if (label == null || value == null) {
          return dev.ServiceExtensionResponse.error(
            dev.ServiceExtensionResponse.invalidParams,
            'Missing label or value parameter',
          );
        }

        final atom = _registeredAtoms.firstWhere((a) => a.label == label);
        final parsedValue = _parseValue(atom.value, value);
        Nano.action(() => atom.value = parsedValue);

        return dev.ServiceExtensionResponse.result(
          json.encode({'status': 'ok'}),
        );
      } catch (e) {
        return dev.ServiceExtensionResponse.error(
          dev.ServiceExtensionResponse.extensionError,
          e.toString(),
        );
      }
    });

    dev.registerExtension('ext.nano.getGraph', (method, parameters) async {
      return dev.ServiceExtensionResponse.result(
        json.encode(getGraphData()),
      );
    });
  }

  /// Returns the current dependency graph as a Map.
  static Map<String, dynamic> getGraphData() {
    final derivationsJson = _registeredDerivations.map((node) {
      return {
        'label': node.debugLabel,
        'type': node.runtimeType.toString(),
        'dependencies': node.dependencies.map((dep) {
          return {
            'label': dep.label ?? 'Atom',
            'type': dep.runtimeType.toString(),
            'value': dep.value.toString(),
          };
        }).toList(),
      };
    }).toList();

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'nodes': derivationsJson,
    };
  }

  static dynamic _parseValue(dynamic originalValue, String valueToParse) {
    if (originalValue is int) {
      return int.parse(valueToParse);
    } else if (originalValue is double) {
      return double.parse(valueToParse);
    } else if (originalValue is bool) {
      return valueToParse == 'true';
    } else if (originalValue is String) {
      return valueToParse;
    }
    // For complex types, we can't parse from string.
    // In a real implementation, this would need a more robust serialization.
    throw Exception('Unsupported type for time travel');
  }

  static String? _getAsyncState(Atom atom) {
    if (atom is AsyncAtom) {
      final state = atom.value;
      if (state is AsyncLoading) return 'loading';
      if (state is AsyncError) return 'error';
      if (state is AsyncData) return 'data';
      return 'idle';
    }
    return null;
  }

  /// Dumps the current dependency graph to the console.
  static void dumpGraph() {
    debugPrint('\n📊 NANO DEPENDENCY GRAPH 📊');
    debugPrint('===========================');
    if (_registeredDerivations.isEmpty) {
      debugPrint('No active derivations found.');
      return;
    }

    for (final node in _registeredDerivations) {
      final deps = node.dependencies;
      debugPrint('${node.debugLabel} depends on:');
      if (deps.isEmpty) {
        debugPrint('  - (none)');
      } else {
        for (final dep in deps) {
          debugPrint('  - ${dep.label ?? dep.runtimeType} (${dep.value})');
        }
      }
      debugPrint('');
    }
    debugPrint('===========================\n');
  }
}

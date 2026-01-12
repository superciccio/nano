import 'dart:developer' as dev;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nano/core/history_observer.dart';
import 'package:nano/core/nano_core.dart';

/// Handles communication between the running app and DevTools.
class NanoDebugService {
  static final List<Atom> _registeredAtoms = [];

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
        json.encode({
          'history': historyJson,
        }),
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
        atom.value = parsedValue;

        return dev.ServiceExtensionResponse.result(json.encode({'status': 'ok'}));
      } catch (e) {
        return dev.ServiceExtensionResponse.error(
          dev.ServiceExtensionResponse.extensionError,
          e.toString(),
        );
      }
    });
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
}

import 'dart:developer' as dev;
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
        };
      }).toList();

      return dev.ServiceExtensionResponse.result(
        json.encode({
          'timestamp': DateTime.now().toIso8601String(),
          'atoms': atomsJson,
        }),
      );
    });
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

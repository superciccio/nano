
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano/core/nano_config.dart';
import 'package:nano/core/nano_core.dart';


void main() {
  test('NanoConfig is isolated by Zone', () async {
    final observerA = RecordingObserver(name: 'A');
    final configA = NanoConfig(observer: observerA);

    final observerB = RecordingObserver(name: 'B');
    final configB = NanoConfig(observer: observerB);

    final atom = Atom(0, label: 'testAtom');

    // Run in Zone A
    await runZoned(() {
      atom.value = 1;
      expect(observerA.changes.length, 1);
      expect(observerA.changes.last.newValue, 1);
      expect(observerB.changes.length, 0); // B should not see this
    }, zoneValues: {#nanoConfig: configA});

    // Run in Zone B
    await runZoned(() {
      atom.value = 2;
      expect(observerB.changes.length, 1);
      expect(observerB.changes.last.newValue, 2);
      expect(observerA.changes.length, 1); // A should not see this (still 1)
    }, zoneValues: {#nanoConfig: configB});
    
    // Verify default observer (no zone config)
    atom.value = 3;
    expect(observerA.changes.length, 1); // Still 1
    expect(observerB.changes.length, 1); // Still 1
  });
}

class RecordingObserver implements NanoObserver {
  final String name;
  final List<({Atom atom, dynamic newValue})> changes = [];
  final List<dynamic> errors = [];

  RecordingObserver({required this.name});

  @override
  void onChange(Atom atom, oldValue, newValue) {
    changes.add((atom: atom, newValue: newValue));
  }

  @override
  void onError(Atom atom, Object error, StackTrace stack) {
    errors.add(error);
  }
}

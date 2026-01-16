import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:nano/core/nano_core.dart';
import 'package:nano/core/nano_logic.dart';

// Alias to avoid conflict if user imports expect from flutter_test
// We use test_package.expect internally
import 'package:flutter_test/flutter_test.dart' as test_package;

/// A declarative test helper for NanoLogic.
///
/// **Nano Compose Philosophy:**
/// Reduces `await` calls and setup noise, making tests read like simple sentences.
///
/// **Usage:**
/// ```dart
/// nanoTest('Counter increments',
///   build: () => CounterLogic(),
///   act: (logic) => logic.increment(),
///   expect: (logic) => [
///     expectLater(logic.count.stream, emits(1)),
///   ],
/// );
/// ```
@isTest
void nanoTest<T extends NanoLogic<dynamic>>(
  String description, {
  required T Function() build,
  FutureOr<void> Function(T logic)? act,
  dynamic Function(T logic)? expect,
  FutureOr<void> Function(T logic)? verify,
  Duration? timeout,
  dynamic tags,
  bool? skip,
}) {
  test(
    description,
    () async {
      final logic = build();

      // Ensure logic is initialized if it relies on init.
      // Ideally user calls init in build if needed, or act.
      // But NanoLogic lifecycle usually starts with view.
      // For unit test, we might want to ensure onInit is called?
      // Let's leave it to the user or assume constructor is enough for unit tests.

      try {
        if (act != null) {
          await act(logic);
        }

        if (expect != null) {
          final result = expect(logic);
          if (result is List) {
            await Future.wait(
                result.map((e) => e is Future ? e : Future.value(e)));
          } else if (result is Future) {
            await result;
          }
        }

        if (verify != null) {
          await verify(logic);
        }
      } finally {
        logic.dispose();
      }
    },
    timeout: timeout != null ? Timeout(timeout) : null,
    tags: tags,
    skip: skip,
  );
}

/// A declarative test helper for Atoms.
///
/// **Usage:**
/// ```dart
/// atomTest<int>(
///   'Counter increments',
///   build: () => Atom(0),
///   act: (a) => a.increment(),
///   expect: [1], // Checks values emitted in order
/// );
/// ```
@isTest
void atomTest<T>(
  String description, {
  required Atom<T> Function() build,
  FutureOr<void> Function(Atom<T> atom)? act,
  dynamic expect, // List<T> or Matcher
  FutureOr<void> Function(Atom<T> atom)? verify,
  Duration? timeout,
  dynamic tags,
  bool? skip,
}) {
  test(
    description,
    () async {
      final atom = build();
      final states = <T>[];
      final subscription = atom.stream.listen(states.add);

      try {
        if (act != null) {
          await act(atom);
        }

        // Wait for microtasks to propagate updates
        await Future.microtask(() {});

        if (expect != null) {
          if (expect is List) {
            test_package.expect(states, test_package.equals(expect));
          } else {
            test_package.expect(states, expect);
          }
        }

        if (verify != null) {
          await verify(atom);
        }
      } finally {
        subscription.cancel();
        atom.dispose();
      }
    },
    timeout: timeout != null ? Timeout(timeout) : null,
    tags: tags,
    skip: skip,
  );
}



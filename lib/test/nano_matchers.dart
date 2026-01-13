import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

/// Waits for [atom] to emit values matching [matchers] in order.
///
/// Example:
/// ```dart
/// await expectLater(atom, emitsInOrder([1, 2, 3]));
/// ```
Stream<T> atomToStream<T>(Atom<T> atom) {
  final controller = StreamController<T>();
  
  // Emit current value immediately? 
  // Standard Stream matchers usually expect future events, but state often has current value.
  // For consistency with Stream.fromIterable, we'll emit current value if it helps,
  // but standard practice for STATE testing is usually "changes from now on".
  // However, `expectLater` works with Streams.
  
  void listener() {
    controller.add(atom.value);
  }

  atom.addListener(listener);
  
  controller.onCancel = () {
    atom.removeListener(listener);
  };
  
  return controller.stream;
}

/// Extension to make testing Atoms easier with standard Matchers.
extension AtomTestExtension<T> on Atom<T> {
  /// Returns a Stream of values emitted by this Atom.
  /// Useful for usage with [expectLater] and [emitsInOrder].
  Stream<T> get stream => atomToStream(this);
}

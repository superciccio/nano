import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:matcher/matcher.dart' as m;
import 'package:nano/nano.dart';

/// Waits for [atom] to emit values matching matchers in order.
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

/// extension to make testing Atoms easier with standard Matchers.
extension AtomTestExtension<T> on Atom<T> {
  /// Returns a Stream of values emitted by this Atom.
  /// Useful for usage with [expectLater] and [emitsInOrder].
  Stream<T> get stream => atomToStream(this);

  /// Creates a [NanoTester] to capture and verify emissions from this Atom.
  NanoTester<T> get tester => NanoTester<T>(this);
}

/// A utility to capture and verify emissions from an [Atom].
class NanoTester<T> {
  final Atom<T> _atom;
  final List<T> _emissions = [];
  late final StreamSubscription<T> _sub;

  NanoTester(this._atom) {
    _sub = _atom.stream.listen(_emissions.add);
  }

  /// The list of values emitted by the atom since this tester was created.
  List<T> get emissions => List.unmodifiable(_emissions);

  /// Clears the captured emissions.
  void clear() => _emissions.clear();

  /// Waits for pending microtasks and verifies that [emissions] match [matcher].
  Future<void> expect(dynamic matcher) async {
    // Standard pump to allow pending microtasks to flush
    await Future.microtask(() {});
    // We allow one extra pump for complex async dependencies
    await Future.delayed(Duration.zero);

    final m.Matcher wrappedMatcher = m.wrapMatcher(matcher);
    final matchState = {};
    if (!wrappedMatcher.matches(_emissions, matchState)) {
      final description = m.StringDescription();
      wrappedMatcher.describeMismatch(
          _emissions, description, matchState, false);
      throw TestFailure(description.toString());
    }
  }

  /// Cancels the internal subscription.
  void dispose() {
    _sub.cancel();
  }
}

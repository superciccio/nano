import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

/// Extension to provide Nano-specific helpers to [WidgetTester].
extension NanoWidgetTester on WidgetTester {
  /// Pumps the widget tree and waits for all Nano async operations to settle.
  Future<void> pumpSettled({
    Duration duration = const Duration(milliseconds: 10),
    int maxIterations = 10,
  }) async {
    await pump();
    for (int i = 0; i < maxIterations; i++) {
      await idle();
      await pump(duration);
      if (!binding.hasScheduledFrame) break;
    }
  }

  /// Resolves a dependency of type [T] from the widget tree.
  T read<T extends Object>() {
    final element = allElements.firstWhere(
      (e) => e.widget.runtimeType.toString() == '_InheritedScope',
      orElse: () => throw TestFailure('No Scope found in the widget tree.'),
    );
    return Scope.of(element).get<T>();
  }
}

/// Extension to provide Nano-specific finders.
extension NanoFinders on CommonFinders {
  /// Finds widgets that are watching the given [atom].
  /// 
  /// Matches [Watch], [AtomBuilder], [AsyncAtomBuilder] and [WatchMany].
  Finder atom(Atom atom) {
    return find.byWidgetPredicate((widget) {
      if (widget is Watch && widget.atom == atom) return true;
      if (widget is WatchMany && widget.atoms.contains(atom)) return true;
      if (widget is AsyncAtomBuilder && widget.atom == atom) return true;
      return false;
    });
  }
}

/// A declarative wrapper around [testWidgets] that handles [Scope] and dependency overrides.

/// A declarative wrapper around [testWidgets] that handles [Scope] and dependency overrides.
/// 
/// Example:
/// ```dart
/// nanoTestWidgets('User flow',
///   overrides: [ 
///     NanoFactory<AuthService>((_) => MockAuthService()) 
///   ],
///   builder: () => const MyApp(),
///   verify: (tester) async {
///     await tester.tap(find.text('Login'));
///     await tester.pumpSettled();
///     expect(find.text('Welcome!'), findsOneWidget);
///   }
/// );
/// ```
void nanoTestWidgets(
  String description, {
  required Widget Function() builder,
  List<Object> modules = const [],
  List<Object> overrides = const [],
  bool skip = false,
  Future<void> Function(WidgetTester tester)? verify,
}) {
  testWidgets(description, (tester) async {
    await tester.pumpWidget(
      Scope(
        modules: modules,
        overrides: overrides,
        child: builder(),
      ),
    );
    
    if (verify != null) {
      await verify(tester);
    }
  }, skip: skip);
}

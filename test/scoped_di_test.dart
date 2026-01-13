import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

void main() {
  group('Scoped Dependency Injection', () {
    testWidgets('Nested Scope should resolve parent dependencies', (
      tester,
    ) async {
      final parentLogic = _ParentLogic();

      await tester.pumpWidget(
        Scope(
          modules: [parentLogic],
          child: Scope(
            modules: [],
            child: Builder(
              builder: (context) {
                final resolved = context.read<_ParentLogic>();
                expect(resolved, parentLogic);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    });

    test(
      'Circular dependencies should throw NanoException with helpful message',
      () {
        final registry = Registry();

        // A depends on B, B depends on A
        registry.registerLazySingleton<_ClassA>(
          (r) => _ClassA(r.get<_ClassB>()),
        );
        registry.registerLazySingleton<_ClassB>(
          (r) => _ClassB(r.get<_ClassA>()),
        );

        expect(
          () => registry.get<_ClassA>(),
          throwsA(
            isA<NanoException>().having(
              (e) => e.message,
              'message',
              contains('Circular dependency detected'),
            ),
          ),
        );
      },
    );
  });
}

class _ParentLogic extends NanoLogic<void> {}

class _ClassA {
  final _ClassB b;
  _ClassA(this.b);
}

class _ClassB {
  final _ClassA a;
  _ClassB(this.a);
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

class MyService {
  final String name;
  MyService(this.name);
}

void main() {
  group('ThrottledAtom', () {
    test('limits updates to once per duration', () async {
      final atom = ThrottledAtom(0, duration: const Duration(milliseconds: 50));
      int count = 0;
      atom.addListener(() => count++);

      atom.value = 1; // Immediate
      atom.value = 2; // Throttled (pending)
      atom.value = 3; // Throttled (pending, overwrites 2)

      expect(atom.value, 1);
      expect(count, 1);

      await Future.delayed(const Duration(milliseconds: 60));
      expect(atom.value, 3);
      expect(count, 2);
    });
  });

  group('ResourceAtom', () {
    test('calls onDispose when disposed', () {
      bool disposed = false;
      final atom = ResourceAtom((ref) {
        ref.onDispose(() => disposed = true);
        return 'Resource';
      });

      expect(atom.value, 'Resource');
      expect(disposed, false);

      atom.dispose();
      expect(disposed, true);
    });

    test('handles multiple disposers', () {
      int disposedCount = 0;
      final atom = ResourceAtom((ref) {
        ref.onDispose(() => disposedCount++);
        ref.onDispose(() => disposedCount++);
        return 42;
      });

      atom.dispose();
      expect(disposedCount, 2);
    });
  });

  group('TimeControl Extensions', () {
    test('debounce extension', () async {
      final source = Atom(0);
      final debounced = source.debounce(const Duration(milliseconds: 50));

      source.value = 1;
      source.value = 2;
      expect(debounced.value, 0);

      await Future.delayed(const Duration(milliseconds: 60));
      expect(debounced.value, 2);
    });

    test('throttle extension', () async {
      final source = Atom(0);
      final throttled = source.throttle(const Duration(milliseconds: 50));

      source.value = 1;
      expect(throttled.value, 1); // Immediate

      source.value = 2;
      expect(throttled.value, 1); // Throttled

      await Future.delayed(const Duration(milliseconds: 60));
      expect(throttled.value, 2);
    });
  });

  group('Scope Overrides', () {
    testWidgets('Scope can override modules', (tester) async {
      final original = MyService('Original');
      final mock = MyService('Mock');

      await tester.pumpWidget(
        Scope(
          modules: [original],
          overrides: [mock],
          child: Container(),
        ),
      );

      final registry = Scope.of(tester.element(find.byType(Container)));
      expect(registry.get<MyService>().name, 'Mock');
    });
  });
}

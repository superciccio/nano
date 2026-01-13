import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

void main() {
  group('Strict Mode Edge Cases', () {
    setUp(() {
      NanoConfig.strictMode = true;
    });

    tearDown(() {
      NanoConfig.strictMode = false;
    });

    test(
      'StreamAtom should NOT throw when updating from stream in strict mode',
      () async {
        final controller = StreamController<int>();
        final atom = StreamAtom<int>(
          controller.stream,
          initial: const AsyncLoading(),
        );

        // This should fail if the internal listener is not wrapped in Nano.action
        controller.add(10);

        // Wait for stream event
        await Future.delayed(Duration.zero);

        expect(atom.value.dataOrNull, 10);
      },
    );

    test(
      'DebouncedAtom should NOT throw when updating from timer in strict mode',
      () async {
        final atom = DebouncedAtom<int>(
          0,
          duration: const Duration(milliseconds: 10),
        );

        // This should fail when the timer fires if not wrapped in Nano.action
        atom.set(100);

        await Future.delayed(const Duration(milliseconds: 20));

        expect(atom.value, 100);
      },
    );

    test(
      'NanoLogic.bindStream should NOT throw when updating atom in strict mode',
      () async {
        final controller = StreamController<int>();
        final atom = Atom<int>(0);
        final logic = _TestLogic();

        logic.bindStream(controller.stream, atom);

        // This should fail if bindStream listener is not wrapped in Nano.action
        controller.add(42);

        await Future.delayed(Duration.zero);

        expect(atom.value, 42);
      },
    );
  });
}

class _TestLogic extends NanoLogic<void> {}

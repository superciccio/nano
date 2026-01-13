import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

void main() {
  group('Nano Exceptions & Safety', () {
    test('side-effect violation should throw when updating atom in onInit', () {
      final atom = Atom(0);
      final logic = _SideEffectLogic(atom);

      expect(
        () => logic.initialize(null),
        throwsA(predicate((e) =>
            e.toString().toLowerCase().contains('side-effect violation') &&
            e.toString().contains('onInit'))),
      );
    });

    test('strict mode violation should throw when updating outside action', () {
      NanoConfig.strictMode = true;
      final atom = Atom(0);

      expect(
        () => atom.value = 1,
        throwsA(predicate((e) =>
            e.toString().contains('Strict Mode Violation') &&
            e.toString().contains('Nano.action'))),
      );

      NanoConfig.strictMode = false;
    });

    test('ComputedAtom should throw UnsupportedError on set', () {
      final a = Atom(1);
      final c = ComputedAtom(() => a.value * 2);

      expect(() => c.set(10), throwsUnsupportedError);
    });

    testWidgets('Scope.of should throw when no Scope is found', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Text(
                () {
                  try {
                    Scope.of(context);
                    return 'Success';
                  } catch (e) {
                    return e.toString();
                  }
                }(),
              );
            },
          ),
        ),
      );

      expect(find.textContaining('No Scope found'), findsOneWidget);
    });

    test('Registry should throw NanoException when service not found', () {
      final registry = Registry();
      expect(
        () => registry.get<String>(),
        throwsA(isA<NanoException>().having(
          (e) => e.message,
          'message',
          contains('not found in the current Scope'),
        )),
      );
    });

    test('Registry should throw NanoException on circular dependency', () {
      final registry = Registry();
      registry.registerFactory<int>((r) => r.get<double>().toInt());
      registry.registerFactory<double>((r) => r.get<int>().toDouble());

      expect(
        () => registry.get<int>(),
        throwsA(isA<NanoException>().having(
          (e) => e.message,
          'message',
          contains('Circular dependency detected'),
        )),
      );
    });
  });
}

class _SideEffectLogic extends NanoLogic<void> {
  final Atom<int> atom;
  _SideEffectLogic(this.atom);

  @override
  void onInit(void params) {
    atom.value = 10;
  }
}

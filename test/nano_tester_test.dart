// ignore_for_file: suggest_nano_action

import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';
import 'package:nano/test.dart';

void main() {
  group('NanoTester', () {
    test('captures emissions', () async {
      final atom = Atom(0);
      final tester = atom.tester;

      atom.value = 1;
      atom.value = 2;

      await tester.expect([1, 2]);
      tester.dispose();
    });

    test('clear() resets captured emissions', () async {
      final atom = Atom(0);
      final tester = atom.tester;

      atom.value = 1;
      await tester.expect([1]);

      tester.clear();
      expect(tester.emissions, isEmpty);

      atom.value = 2;
      await tester.expect([2]);
      tester.dispose();
    });

    test('handles async updates', () async {
      final atom = Atom(0);
      final tester = atom.tester;

      Future(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        atom.value = 10;
        await Future.delayed(const Duration(milliseconds: 10));
        atom.value = 20;
      });

      // Wait for the async flow to complete
      await Future.delayed(const Duration(milliseconds: 50));

      await tester.expect([10, 20]);
      tester.dispose();
    });

    test('integration with standard matchers (contains, length)', () async {
      final atom = Atom(0);
      final tester = atom.tester;

      atom.value = 1;
      atom.value = 2;
      atom.value = 3;

      await tester.expect(contains(2));
      await tester.expect(hasLength(3));
      await tester.expect(orderedEquals([1, 2, 3]));

      tester.dispose();
    });
  });
}

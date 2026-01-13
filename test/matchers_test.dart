// ignore_for_file: suggest_nano_action
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';
import 'package:nano/test.dart';

void main() {
  test('Atom.stream works with emitsInOrder', () async {
    final counter = Atom(0);

    // Schedule updates
    Future.microtask(() {
      counter.value = 1;
      counter.value = 2;
      counter.value = 3;
    });

    // Verify stream of changes
    await expectLater(
      counter.stream,
      emitsInOrder([1, 2, 3]),
    );
  });

  test('Atom.stream handles async updates', () async {
    final text = Atom('start');

    Future(() async {
      await Future.delayed(const Duration(milliseconds: 10));
      text.value = 'middle';
      await Future.delayed(const Duration(milliseconds: 10));
      text.value = 'end';
    });

    await expectLater(
      text.stream,
      emitsInOrder(['middle', 'end']),
    );
  });
}

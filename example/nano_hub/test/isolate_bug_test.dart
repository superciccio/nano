import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';
import 'dart:isolate';

void main() {
  test('reproduce isolate serialization error with AsyncState', () async {
    final state = AsyncData(1.0);

    print("Testing AsyncData serialization...");
    await Isolate.run(() {
      print("Inside isolate with: $state");
      return state;
    });
  });

  test('reproduce isolate serialization error with AsyncLoading', () async {
    final state = const AsyncLoading<double>();

    print("Testing AsyncLoading serialization...");
    await Isolate.run(() {
      print("Inside isolate with: $state");
      return state;
    });
  });
}

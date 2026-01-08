import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

void main() {
  group('Registry', () {
    test('registers and retrieves a service', () {
      final registry = Registry();
      final service = _MockService();
      registry.register<_MockService>(service);

      expect(registry.get<_MockService>(), service);
    });

    test('throws NanoException when service is missing', () {
      final registry = Registry();
      expect(() => registry.get<_MockService>(), throwsA(isA<NanoException>()));
    });

    test('retrieves correct type with multiple services', () {
      final registry = Registry();
      final s1 = _MockService();
      final s2 = _AnotherService();

      registry.register<_MockService>(s1);
      registry.register<_AnotherService>(s2);

      expect(registry.get<_MockService>(), s1);
      expect(registry.get<_AnotherService>(), s2);
    });
  });
}

class _MockService {}

class _AnotherService {}

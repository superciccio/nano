import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/core/nano_di.dart';

void main() {
  group('Registry', () {
    test('registers and retrieves singleton instance', () {
      final reg = Registry();
      final instance = _Service();
      reg.register(instance);
      expect(reg.get<_Service>(), instance);
    });

    test('registers and retrieves factory', () {
      final reg = Registry();
      reg.registerFactory((r) => _Service());

      final i1 = reg.get<_Service>();
      final i2 = reg.get<_Service>();

      expect(i1, isA<_Service>());
      expect(i2, isA<_Service>());
      expect(i1, isNot(equals(i2)));
    });

    test('registers and retrieves lazy singleton', () {
      final reg = Registry();
      int createCount = 0;
      reg.registerLazySingleton((r) {
        createCount++;
        return _Service();
      });

      expect(createCount, 0);
      final i1 = reg.get<_Service>();
      expect(createCount, 1);
      final i2 = reg.get<_Service>();
      expect(createCount, 1);
      expect(i1, equals(i2));
    });

    test('registerFactoryDynamic works', () {
      final reg = Registry();
      reg.registerFactoryDynamic(_Service, (r) => _Service());
      expect(reg.get<_Service>(), isA<_Service>());
    });

    test('registerLazySingletonDynamic works', () {
      final reg = Registry();
      reg.registerLazySingletonDynamic(_Service, (r) => _Service());
      expect(reg.get<_Service>(), isA<_Service>());
    });

    test('throws when service not found', () {
      final reg = Registry();
      expect(() => reg.get<_Service>(), throwsA(isA<NanoException>()));
    });

    test('debugFillProperties works', () {
      final reg = Registry();
      reg.register(_Service());
      reg.registerFactory<_FactoryService>((r) => _FactoryService());
      reg.registerLazySingleton<_LazyService>((r) => _LazyService());

      final builder = DiagnosticPropertiesBuilder();
      reg.debugFillProperties(builder);

      final props = builder.properties;
      expect(props.any((p) => p.name == '_Service'), isTrue);
      expect(props.any((p) => p.name == 'Factory<_FactoryService>'), isTrue);
      expect(props.any((p) => p.name == 'Lazy<_LazyService>'), isTrue);
    });

    test('NanoException has string representation', () {
      final e = NanoException("Foo");
      expect(e.toString(), "NanoException: Foo");
    });

    test('NanoFactory wrapper works', () {
      final f = NanoFactory((r) => _Service());
      expect(f.type, _Service);
      expect(f.create(Registry()), isA<_Service>());
    });

    test('NanoLazy wrapper works', () {
      final l = NanoLazy((r) => _Service());
      expect(l.type, _Service);
      expect(l.create(Registry()), isA<_Service>());
    });
  });
}

class _Service {}

class _FactoryService {}

class _LazyService {}

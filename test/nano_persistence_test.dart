import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

class MockStorage implements NanoStorage {
  final Map<String, String> data = {};

  @override
  Future<void> delete(String key) async => data.remove(key);

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;
}

void main() {
  group('PersistedAtom', () {
    late MockStorage storage;

    setUp(() {
      storage = MockStorage();
      Nano.storage = storage;
    });

    test('loads from storage on init', () async {
      storage.data['test_key'] = '100';

      final atom = PersistedAtom(0, key: 'test_key');

      // Wait for async load
      await Future.delayed(Duration.zero);

      expect(atom.value, 100);
    });

    test('saves to storage on set', () async {
      final atom = PersistedAtom(0, key: 'test_key');

      atom.value = 50;

      await Future.delayed(Duration.zero);

      expect(storage.data['test_key'], '50');
    });

    test('handles complex types with codecs', () async {
      storage.data['bool_key'] = 'true';

      final atom = PersistedAtom<bool>(
        false,
        key: 'bool_key',
        fromString: (s) => s == 'true',
        toStringEncoder: (b) => b.toString(),
      );

      await Future.delayed(Duration.zero);
      expect(atom.value, true);

      atom.value = false;
      await Future.delayed(Duration.zero);
      expect(storage.data['bool_key'], 'false');
    });
  });
}

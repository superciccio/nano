import 'dart:async'; // Add async import
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
    // setUp removed

    test('loads from storage on init', () async {
      final storage = MockStorage();
      final config = NanoConfig(storage: storage);
      storage.data['test_key'] = '100';

      await runZoned(() async {
        final atom = PersistedAtom(0, key: 'test_key');
        await Future.delayed(Duration.zero);
        expect(atom.value, 100);
      }, zoneValues: {#nanoConfig: config});
    });

    test('saves to storage on set', () async {
      final storage = MockStorage();
      final config = NanoConfig(storage: storage);

      await runZoned(() async {
        final atom = PersistedAtom(0, key: 'test_key');
        atom.value = 50;
        await Future.delayed(Duration.zero);
        expect(storage.data['test_key'], '50');
      }, zoneValues: {#nanoConfig: config});
    });

    test('handles complex types with codecs', () async {
      final storage = MockStorage();
      final config = NanoConfig(storage: storage);
      storage.data['bool_key'] = 'true';

      await runZoned(() async {
        final atom = PersistAtom<bool>(
          false,
          key: 'bool_key',
          fromString: (s) => s == 'true',
          toJson: (b) => b.toString(),
        );

        await Future.delayed(Duration.zero);
        expect(atom.value, true);

        atom.value = false;
        await Future.delayed(Duration.zero);
        expect(storage.data['bool_key'], 'false');
      }, zoneValues: {#nanoConfig: config});
    });
  });
}

/// Interface for storage backend.
abstract class NanoStorage {
  /// Reads a value from storage.
  Future<String?> read(String key);

  /// Writes a value to storage.
  Future<void> write(String key, String value);

  /// Deletes a value from storage.
  Future<void> delete(String key);
}

/// A simple in-memory storage implementation (default).
class InMemoryStorage implements NanoStorage {
  final _data = <String, String>{};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);
}

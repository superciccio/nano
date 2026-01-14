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

/// A storage implementation that uses `SharedPreferences`.
/// This requires the `shared_preferences` package to be available in the project.
class SharedPrefsStorage implements NanoStorage {
  final dynamic _prefs;

  SharedPrefsStorage(this._prefs);

  @override
  Future<String?> read(String key) async {
    final val = _prefs.get(key);
    if (val == null) return null;
    return val.toString();
  }

  @override
  Future<void> write(String key, String value) async {
    if (value == 'true' || value == 'false') {
      await _prefs.setBool(key, value == 'true');
    } else if (int.tryParse(value) != null) {
      await _prefs.setInt(key, int.parse(value));
    } else if (double.tryParse(value) != null) {
      await _prefs.setDouble(key, double.parse(value));
    } else {
      await _prefs.setString(key, value);
    }
  }

  @override
  Future<void> delete(String key) async {
    await _prefs.remove(key);
  }
}

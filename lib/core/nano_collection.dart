import 'dart:collection';
import 'nano_core.dart';

/// A [List] that automatically tracks reads and notifies on writes.
///
/// Use this when you want mutable lists that trigger UI updates.
class NanoList<E> with ListMixin<E> {
  final List<E> _inner;
  final Atom<int> _signal;

  NanoList([Iterable<E>? initial, String? label])
      : _inner = initial?.toList() ?? <E>[],
        _signal = Atom(0, label: label ?? 'NanoList');

  void _notify() => _signal.value++;

  @override
  int get length {
    Nano.reportRead(_signal);
    return _inner.length;
  }

  @override
  set length(int newLength) {
    // Note: Setting length on a list of non-nullable types will throw
    // if expanding. Use .add or .insert instead for non-nullable lists.
    if (_inner.length != newLength) {
      _inner.length = newLength;
      _notify();
    }
  }

  @override
  E operator [](int index) {
    Nano.reportRead(_signal);
    return _inner[index];
  }

  @override
  void operator []=(int index, E value) {
    if (_inner[index] != value) {
      _inner[index] = value;
      _notify();
    }
  }

  // --- Optimized Overrides (Bypass ListMixin for safety & speed) ---

  @override
  void add(E element) {
    _inner.add(element);
    _notify();
  }

  @override
  void addAll(Iterable<E> iterable) {
    _inner.addAll(iterable);
    _notify();
  }

  @override
  void insert(int index, E element) {
    _inner.insert(index, element);
    _notify();
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    _inner.insertAll(index, iterable);
    _notify();
  }

  @override
  bool remove(Object? element) {
    if (_inner.remove(element)) {
      _notify();
      return true;
    }
    return false;
  }

  @override
  E removeAt(int index) {
    final result = _inner.removeAt(index);
    _notify();
    return result;
  }

  @override
  E removeLast() {
    final result = _inner.removeLast();
    _notify();
    return result;
  }

  @override
  void removeWhere(bool Function(E element) test) {
    // _inner.removeWhere doesn't return info if it changed.
    // We can check length before/after or just notify conservatively.
    final len = _inner.length;
    _inner.removeWhere(test);
    if (_inner.length != len) _notify();
  }

  @override
  void retainWhere(bool Function(E element) test) {
    final len = _inner.length;
    _inner.retainWhere(test);
    if (_inner.length != len) _notify();
  }

  @override
  void clear() {
    if (_inner.isNotEmpty) {
      _inner.clear();
      _notify();
    }
  }
}

/// A [Map] that automatically tracks reads and notifies on writes.
class NanoMap<K, V> with MapMixin<K, V> {
  final Map<K, V> _inner;
  final Atom<int> _signal;

  NanoMap([Map<K, V>? initial, String? label])
      : _inner = initial ?? {},
        _signal = Atom(0, label: label ?? 'NanoMap');

  void _notify() => _signal.value++;

  @override
  V? operator [](Object? key) {
    Nano.reportRead(_signal);
    return _inner[key];
  }

  @override
  void operator []=(K key, V value) {
    if (_inner[key] != value) {
      _inner[key] = value;
      _notify();
    }
  }

  @override
  void clear() {
    if (_inner.isNotEmpty) {
      _inner.clear();
      _notify();
    }
  }

  @override
  Iterable<K> get keys {
    Nano.reportRead(_signal);
    return _inner.keys;
  }

  @override
  V? remove(Object? key) {
    if (_inner.containsKey(key)) {
      final result = _inner.remove(key);
      _notify();
      return result;
    }
    return null;
  }
  
  @override
  void addAll(Map<K, V> other) {
    _inner.addAll(other);
    _notify();
  }
}

/// A [Set] that automatically tracks reads and notifies on writes.
class NanoSet<E> with SetMixin<E> {
  final Set<E> _inner;
  final Atom<int> _signal;

  NanoSet([Set<E>? initial, String? label])
      : _inner = initial ?? {},
        _signal = Atom(0, label: label ?? 'NanoSet');

  void _notify() => _signal.value++;

  @override
  bool add(E value) {
    if (_inner.add(value)) {
      _notify();
      return true;
    }
    return false;
  }

  @override
  bool contains(Object? element) {
    Nano.reportRead(_signal);
    return _inner.contains(element);
  }

  @override
  Iterator<E> get iterator {
    Nano.reportRead(_signal);
    return _inner.iterator;
  }

  @override
  int get length {
    Nano.reportRead(_signal);
    return _inner.length;
  }

  @override
  E? lookup(Object? element) {
    Nano.reportRead(_signal);
    return _inner.lookup(element);
  }

  @override
  bool remove(Object? value) {
    if (_inner.remove(value)) {
      _notify();
      return true;
    }
    return false;
  }

  @override
  Set<E> toSet() {
    Nano.reportRead(_signal);
    return _inner.toSet();
  }
  
  @override
  void addAll(Iterable<E> elements) {
    final len = _inner.length;
    _inner.addAll(elements);
    if (_inner.length != len) _notify();
  }
  
  @override
  void removeAll(Iterable<Object?> elements) {
    final len = _inner.length;
    _inner.removeAll(elements);
    if (_inner.length != len) _notify();
  }

  @override
  void clear() {
    if (_inner.isNotEmpty) {
      _inner.clear();
      _notify();
    }
  }
}
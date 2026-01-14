import 'package:nano/core/nano_core.dart';

typedef Validator<T> = String? Function(T value);

/// A library of common validators.
class Validators {
  static Validator<T> required<T>() {
    return (value) {
      if (value == null) return 'Required';
      if (value is String && value.trim().isEmpty) return 'Required';
      if (value is Iterable && value.isEmpty) return 'Required';
      return null;
    };
  }

  static Validator<String> minLength(int length) {
    return (value) {
      if (value.length < length) return 'Min length is $length';
      return null;
    };
  }

  static Validator<String> email() {
    return (value) {
      if (value.isEmpty) return null; // Let required handle empty
      if (!value.contains('@')) return 'Invalid email';
      return null;
    };
  }
}

/// An Atom that manages form field state including validation.
class FieldAtom<T> extends ValueAtom<T> {
  final List<Validator<T>> validators;
  final T _initialValue;
  // ignore: avoid_atom_outside_logic
  final Atom<String?> _error = Atom(null);

  /// Whether validation has run at least once (touched).
  bool _touched = false;

  FieldAtom(
    T initial, {
    this.validators = const [],
    super.label,
  })  : _initialValue = initial,
        super(initial);

  /// The current error message, if any.
  /// Returns null if valid or not yet validated.
  String? get error {
    Nano.reportRead(_error);
    return _error.value;
  }

  /// The error atom for tracking in UI.
  Atom<String?> get errorAtom => _error;

  /// Whether the field is currently valid.
  bool get isValid => _error.value == null;

  @override
  void set(T newValue) {
    super.set(newValue);
    if (_touched) {
      validate();
    }
  }

  /// Runs all validators and updates [error].
  /// Returns true if valid.
  bool validate() {
    _touched = true;
    for (final validator in validators) {
      final result = validator(value);
      if (result != null) {
        _error.value = result;
        return false;
      }
    }
    _error.value = null;
    return true;
  }

  /// Resets the field to initial state and clears errors.
  void reset() {
    _touched = false;
    value = _initialValue;
    _error.value = null;
  }
}

/// Aggregates multiple [FieldAtom]s.
class FormAtom {
  final List<FieldAtom> fields;

  FormAtom(this.fields);

  /// Whether the whole form is valid.
  bool get isValid => fields.every((f) => f.isValid);

  /// An atom that tracks the validity of the whole form.
  late final Atom<bool> isValidAtom = computed(() => isValid);

  /// Validates all fields immediately.
  bool validate() {
    bool allValid = true;
    for (final field in fields) {
      if (!field.validate()) {
        allValid = false;
      }
    }
    return allValid;
  }

  /// Resets all fields.
  void reset() {
    for (final field in fields) {
      field.reset();
    }
  }
}

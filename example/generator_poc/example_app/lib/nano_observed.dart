import 'package:flutter/widgets.dart';
import 'package:nano/nano.dart';

/// A widget that rebuilds when any Atom read inside [builder] changes.
class NanoObserved extends StatefulWidget {
  final WidgetBuilder builder;

  const NanoObserved({super.key, required this.builder});

  @override
  State<NanoObserved> createState() => _NanoObservedState();
}

class _NanoObservedState extends State<NanoObserved> implements NanoDerivation {
  Set<Atom> _dependencies = {};
  Set<Atom>? _newDependencies;

  @override
  String get debugLabel => 'NanoObserved';

  @override
  Iterable<Atom> get dependencies => _dependencies;

  @override
  void addDependency(Atom atom) {
    if (_newDependencies != null) {
      _newDependencies!.add(atom);
    }
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  void _unsubscribe() {
    for (final atom in _dependencies) {
      atom.removeListener(_handleChange);
    }
    _dependencies.clear();
  }

  void _handleChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _newDependencies = {};
    try {
      // Execute the builder within Nano's tracking scope.
      // We pass 'this' as the derivation so 'addDependency' is called on us.
      return Nano.track(this, () => widget.builder(context));
    } finally {
      // Diff dependencies
      for (final atom in _dependencies) {
        if (!_newDependencies!.contains(atom)) {
          atom.removeListener(_handleChange);
        }
      }

      for (final atom in _newDependencies!) {
        if (!_dependencies.contains(atom)) {
          atom.addListener(_handleChange);
        }
      }

      _dependencies = _newDependencies!;
      _newDependencies = null;
    }
  }
}

/// Helper to access Logic from context (Classic Scope lookup)
extension NanoContextExtension on BuildContext {
  T use<T extends Object>() {
    // Currently Nano doesn't have a direct 'context.read<T>' for generic objects unless they are in Scope?
    // Nano Scope uses `Scope.of(context).get<T>()`.
    // Let's check `nano_flutter.dart` -> `src/scope.dart`.
    return Scope.of(this).get<T>();
  }
}

import 'package:flutter/widgets.dart';
import 'package:nano/nano.dart';

/// A widget that implicitly tracks any [Atom] accessed within its [builder].
///
/// This eliminates the need for manual `.watch()` calls.
///
/// Example:
/// ```dart
/// NanoConsumer(
///   builder: (context) {
///     final logic = context.use<MyLogic>();
///     return Text('${logic.count}'); // Automatically rebuilds when count changes
///   }
/// )
/// ```
class NanoConsumer extends StatefulWidget {
  final WidgetBuilder builder;

  const NanoConsumer({super.key, required this.builder});

  @override
  State<NanoConsumer> createState() => _NanoConsumerState();
}

class _NanoConsumerState extends State<NanoConsumer> implements NanoDerivation {
  Set<Atom> _dependencies = {};
  Set<Atom>? _newDependencies;

  @override
  String get debugLabel => 'NanoConsumer';

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
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    _newDependencies = {};
    try {
      // Execute the builder within Nano's tracking scope.
      // We pass 'this' as the derivation so 'addDependency' is called on us.
      // Nano.track returns the result of the closure (Widget).
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
    return Scope.of(this).get<T>();
  }
}

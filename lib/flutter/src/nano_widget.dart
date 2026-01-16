import 'package:flutter/widgets.dart';
import '../../core/nano_core.dart';

/// Mixin to make any [State] react to [Atom] changes automatically.
mixin NanoStateMixin<T extends StatefulWidget> on State<T> implements NanoDerivation {
  Set<Atom> _dependencies = {};
  Set<Atom>? _newDependencies;

  @override
  String get debugLabel => 'NanoWidget(${widget.runtimeType})';

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

  /// Call this method inside your build method to track dependencies.
  Widget track(Widget Function() builder) {
    _newDependencies = {};
    try {
      return Nano.track(this, builder);
    } finally {
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

/// A substitute for [StatelessWidget] that automatically tracks [Atom]s.
///
/// Use this widget when you want your UI to automatically rebuild whenever
/// an [Atom] it reads changes.
abstract class NanoStatelessWidget extends StatefulWidget {
  const NanoStatelessWidget({super.key});

  @override
  State<NanoStatelessWidget> createState() => _NanoStatelessWidgetState();

  @protected
  Widget build(BuildContext context);
}

class _NanoStatelessWidgetState extends State<NanoStatelessWidget> with NanoStateMixin {
  @override
  Widget build(BuildContext context) {
    return track(() => widget.build(context));
  }
}

/// A widget that tracks [Atom]s accessed in its [builder].
///
/// Use this when you want a small part of your UI to react to changes,
/// without creating a separate [NanoStatelessWidget].
class NanoConsumer extends StatefulWidget {
  final WidgetBuilder builder;

  const NanoConsumer({super.key, required this.builder});

  @override
  State<NanoConsumer> createState() => _NanoConsumerState();
}

class _NanoConsumerState extends State<NanoConsumer> with NanoStateMixin {
  @override
  Widget build(BuildContext context) {
    return track(() => widget.builder(context));
  }
}

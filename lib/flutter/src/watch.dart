import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nano/core/nano_core.dart';

/// Surgical rebuilds.
///
/// Only rebuilds this widget when the specific [ValueListenable] (usually an
/// [Atom] or [ComputedAtom]) changes.
///
/// This widget is highly optimized. It is a [StatefulWidget] that listens
/// directly to the atom, avoiding the overhead of extra widget layers like
/// `ValueListenableBuilder`.
///
/// Example:
/// ```dart
/// Watch(logic.counter, builder: (context, value) {
///   return Text('$value');
/// })
/// ```
class Watch<T> extends StatefulWidget {
  /// The [ValueListenable] (usually an [Atom] or [ComputedAtom]) to watch.
  final ValueListenable<T> atom;

  /// The UI Builder.
  final Widget Function(BuildContext context, T value) builder;

  const Watch(this.atom, {super.key, required this.builder});

  @override
  State<Watch<T>> createState() => _WatchState<T>();
}

class _WatchState<T> extends State<Watch<T>> {
  @override
  void initState() {
    super.initState();
    widget.atom.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(Watch<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.atom != widget.atom) {
      oldWidget.atom.removeListener(_handleChange);
      widget.atom.addListener(_handleChange);
    }
  }

  @override
  void dispose() {
    widget.atom.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.atom.value);
  }
}

/// Batched rebuilds for multiple atoms.
///
/// This widget is highly optimized. It listens directly to the list of atoms
/// and rebuilds only once even if multiple atoms change in the same batch.
class WatchMany extends StatefulWidget {
  /// The list of [ValueListenable] (atoms) to watch.
  final List<ValueListenable> atoms;

  /// The UI Builder.
  final Widget Function(BuildContext context) builder;

  const WatchMany(this.atoms, {super.key, required this.builder});

  @override
  State<WatchMany> createState() => _WatchManyState();
}

class _WatchManyState extends State<WatchMany> {
  @override
  void initState() {
    super.initState();
    for (final atom in widget.atoms) {
      atom.addListener(_handleChange);
    }
  }

  @override
  void didUpdateWidget(WatchMany oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.atoms, widget.atoms)) {
      for (final atom in oldWidget.atoms) {
        atom.removeListener(_handleChange);
      }
      for (final atom in widget.atoms) {
        atom.addListener(_handleChange);
      }
    }
  }

  @override
  void dispose() {
    for (final atom in widget.atoms) {
      atom.removeListener(_handleChange);
    }
    super.dispose();
  }

  void _handleChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}

/// A simplified builder for [Atom]s. Alias for [Watch].
///
/// Example:
/// ```dart
/// AtomBuilder(
///   atom: count,
///   builder: (context, value) => Text('$value'),
/// )
/// ```
class AtomBuilder<T> extends Watch<T> {
  const AtomBuilder({
    super.key,
    required ValueListenable<T> atom,
    required super.builder,
  }) : super(atom);
}

/// A specialized builder for [AsyncAtom] (or any `ValueListenable<AsyncState<T>>`).
///
/// Simplifies handling of loading, error, and data states without nested maps.
///
/// Example:
/// ```dart
/// AsyncAtomBuilder(
///   atom: userAtom,
///   data: (context, user) => UserProfile(user),
///   loading: (context) => const CircularProgressIndicator(),
///   error: (context, error) => ErrorText(error),
/// )\n/// ```
class AsyncAtomBuilder<T> extends StatelessWidget {
  final ValueListenable<AsyncState<T>> atom;
  final Widget Function(BuildContext context, T data) data;
  final Widget Function(BuildContext context, Object error) error;
  final Widget Function(BuildContext context) loading;
  final Widget Function(BuildContext context)? idle;

  const AsyncAtomBuilder({
    super.key,
    required this.atom,
    required this.data,
    required this.error,
    required this.loading,
    this.idle,
  });

  @override
  Widget build(BuildContext context) {
    return Watch<AsyncState<T>>(
      atom,
      builder: (context, state) {
        return state.map(
          data: (d) => data(context, d),
          error: (e) => error(context, e),
          loading: () => loading(context),
          idle: () => idle?.call(context) ?? loading(context),
        );
      },
    );
  }
}

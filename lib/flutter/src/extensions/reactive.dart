import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:nano/core/nano_core.dart';
import '../watch.dart';

/// Ergonomic extensions for any [ValueListenable] to create a [Watch] widget.
extension ValueListenableWatcher<T> on ValueListenable<T> {
  /// Creates a [Watch] widget from this [ValueListenable].
  ///
  /// Example:
  /// ```dart
  /// logic.counter.watch((context, value) {
  ///   return Text('$value');
  /// })
  /// ```
  Widget watch(Widget Function(BuildContext context, T value) builder) {
    return Watch<T>(this, builder: builder);
  }
}

/// Ergonomic extensions for Tuple (Record) of 2 [ValueListenable]s.
extension NanoTuple2Extension<T1, T2> on (
  ValueListenable<T1>,
  ValueListenable<T2>
) {
  /// Watches both atoms and rebuilds when either changes.
  ///
  /// Example:
  /// ```dart
  /// (count, name).watch((context, c, n) {
  ///   return Text('$n: $c');
  /// })
  /// ```
  Widget watch(Widget Function(BuildContext context, T1 v1, T2 v2) builder) {
    return WatchMany([
      this.$1,
      this.$2,
    ], builder: (context) => builder(context, this.$1.value, this.$2.value));
  }
}

/// Ergonomic extensions for Tuple (Record) of 3 [ValueListenable]s.
extension NanoTuple3Extension<T1, T2, T3> on (
  ValueListenable<T1>,
  ValueListenable<T2>,
  ValueListenable<T3>
) {
  /// Watches all 3 atoms and rebuilds when any changes.
  Widget watch(
    Widget Function(BuildContext context, T1 v1, T2 v2, T3 v3) builder,
  ) {
    return WatchMany(
      [this.$1, this.$2, this.$3],
      builder: (context) =>
          builder(context, this.$1.value, this.$2.value, this.$3.value),
    );
  }
}

/// Ergonomic extensions for [ValueListenable] of [AsyncState].
extension AsyncAtomWidgetExtension<T> on ValueListenable<AsyncState<T>> {
  /// Watches the [AsyncState] and builds widgets based on the state.
  Widget when({
    required Widget Function(BuildContext context, T data) data,
    required Widget Function(BuildContext context, Object error) error,
    required Widget Function(BuildContext context) loading,
    Widget Function(BuildContext context)? idle,
  }) {
    return watch((context, state) {
      return state.map(
        data: (d) => data(context, d),
        error: (e) => error(context, e),
        loading: () => loading(context),
        idle: () => idle?.call(context) ?? loading(context),
      );
    });
  }
}

/// Extensions for [ValueListenable] to create reactive Text widgets.
extension AtomTextWidgetExtension<T> on ValueListenable<T> {
  /// Returns a [Text] widget that rebuilds when the atom changes.
  Widget text({
    String Function(T value)? format,
    TextStyle? style,
  }) {
    return watch((context, value) {
      final display = format != null ? format(value) : value.toString();
      return Text(display, style: style);
    });
  }
}

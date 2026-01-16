import 'package:flutter/widgets.dart';
import '../scope.dart';

/// Ergonomic extensions for [BuildContext].
extension NanoContextExtension on BuildContext {
  /// Reads a dependency of type [T] from the nearest [Scope].
  ///
  /// Short for `Scope.of(this).get<T>()`.
  T read<T>() => Scope.of(this).get<T>();

  /// Alias for [read]. Often used in functional components.
  T use<T>() => read<T>();
}

/// Extensions for functional logic access.
extension NanoContextLogicExtension on BuildContext {
  /// Fast access to a [NanoLogic] registered in the [Scope] tree.
  ///
  /// This is the preferred way to access logic in [StatelessWidget]s
  /// when using the 'Composite' pattern.
  T logic<T>() => Scope.of(this).get<T>();

  /// Creates a new instance of a dependency of type [T] using a factory.
  T factory<T>() => Scope.of(this).get<T>();
}

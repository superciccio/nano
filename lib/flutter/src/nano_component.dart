import 'package:flutter/widgets.dart';
import 'scope.dart';
import 'nano_widget.dart';

/// A convenience widget that combines a [Scope] and a reactive view.
///
/// Use this to create a self-contained component that defines its own dependencies
/// and reacts to them, without needing two separate classes (Wrapper + View).
///
/// Example:
/// ```dart
/// class CounterComponent extends NanoComponent {
///   @override
///   List<Object> get modules => [NanoLazy((_) => CounterLogic())];
///
///   @override
///   Widget view(BuildContext context) {
///     final logic = context.read<CounterLogic>();
///     return Text('${logic.count}');
///   }
/// }
/// ```
abstract class NanoComponent extends StatelessWidget {
  const NanoComponent({super.key});

  /// The list of dependencies to register for this component.
  List<Object> get modules;

  /// The reactive view of the component.
  /// This method is automatically tracked (rebuilds when atoms change).
  Widget view(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return Scope(
      modules: modules,
      child: NanoConsumer(builder: view),
    );
  }
}

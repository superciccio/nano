import 'package:flutter/widgets.dart';

/// Ergonomic extensions for [Widget] to apply layout modifiers.
extension NanoWidgetModifierExtension on Widget {
  /// Wraps the widget in a [Padding].
  Widget padding([EdgeInsetsGeometry padding = const EdgeInsets.all(0)]) =>
      Padding(padding: padding, child: this);

  /// Wraps the widget in a [Center].
  Widget center() => Center(child: this);

  /// Wraps the widget in an [Expanded].
  Widget expanded({int flex = 1}) => Expanded(flex: flex, child: this);

  /// Wraps the widget in a [Flexible].
  Widget flexible({int flex = 1, FlexFit fit = FlexFit.loose}) =>
      Flexible(flex: flex, fit: fit, child: this);

  /// Wraps the widget in a [GestureDetector] with [onTap].
  Widget onTap(VoidCallback onTap) =>
      GestureDetector(onTap: onTap, child: this);

  /// Wraps the widget in an [Align].
  Widget align(AlignmentGeometry alignment) =>
      Align(alignment: alignment, child: this);

  /// Wraps the widget in a [SizedBox] with fixed width/height.
  Widget size({double? width, double? height}) =>
      SizedBox(width: width, height: height, child: this);
}

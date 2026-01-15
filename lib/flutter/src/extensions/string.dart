import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Ergonomic extensions for [String] to create Text widgets.
extension NanoStringExtension on String {
  /// Returns a [Text] widget.
  Text text({TextStyle? style}) => Text(this, style: style);

  /// Returns a bold [Text] widget.
  Text bold({double fontSize = 16, Color? color}) => Text(
        this,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
          color: color,
        ),
      );
}

/// Extensions for [ValueListenable] to create reactive buttons.
extension ValueListenableButtonExtension<T> on ValueListenable<T> {
  /// Returns a [FilledButton] that is only enabled if the atom has a 'truthy' value.
  Widget button(String label, {required VoidCallback onPressed}) {
    return ValueListenableBuilder<T>(
      valueListenable: this,
      builder: (context, value, _) {
        final isEnabled = value is bool ? value : value != null;
        return FilledButton(
          onPressed: isEnabled ? onPressed : null,
          child: Text(label),
        );
      },
    );
  }
}

/// Ergonomic extensions for [String] to create Action widgets (Buttons).
extension NanoStringActionExtension on String {
  /// Returns a [TextButton].
  Widget textButton({required VoidCallback onPressed}) =>
      TextButton(onPressed: onPressed, child: Text(this));

  /// Returns a [FilledButton].
  Widget filledButton({required VoidCallback onPressed}) =>
      FilledButton(onPressed: onPressed, child: Text(this));

  /// Returns an [ElevatedButton].
  Widget elevatedButton({required VoidCallback onPressed}) =>
      ElevatedButton(onPressed: onPressed, child: Text(this));

  /// Returns an [OutlinedButton].
  Widget outlinedButton({required VoidCallback onPressed}) =>
      OutlinedButton(onPressed: onPressed, child: Text(this));
}

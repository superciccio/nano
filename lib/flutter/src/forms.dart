import 'package:flutter/material.dart';
import 'package:nano/core/nano_forms.dart';
import 'extensions/reactive.dart';

/// A specialized [TextField] that binds directly to a [FieldAtom<String>].
///
/// It manages its own [TextEditingController] and automatically displays
/// validation errors from the atom.
class NanoTextField extends StatefulWidget {
  final FieldAtom<String> field;
  final String? label;
  final String? hint;
  final int maxLines;
  final bool obscureText;
  final InputDecoration? decoration;
  final TextStyle? style;
  final ValueChanged<String>? onChanged;

  const NanoTextField({
    super.key,
    required this.field,
    this.label,
    this.hint,
    this.maxLines = 1,
    this.obscureText = false,
    this.decoration,
    this.style,
    this.onChanged,
  });

  @override
  State<NanoTextField> createState() => _NanoTextFieldState();
}

class _NanoTextFieldState extends State<NanoTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.field.value);
    widget.field.addListener(_handleAtomChange);
    _controller.addListener(_handleControllerChange);
  }

  void _handleAtomChange() {
    if (_controller.text != widget.field.value) {
      _controller.text = widget.field.value;
    }
  }

  void _handleControllerChange() {
    if (widget.field.value != _controller.text) {
      widget.field.set(_controller.text);
      widget.onChanged?.call(_controller.text);
    }
  }

  @override
  void didUpdateWidget(NanoTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.field != widget.field) {
      oldWidget.field.removeListener(_handleAtomChange);
      widget.field.addListener(_handleAtomChange);
      _controller.text = widget.field.value;
    }
  }

  @override
  void dispose() {
    widget.field.removeListener(_handleAtomChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDecoration =
        (widget.decoration ?? const InputDecoration()).copyWith(
      labelText: widget.label,
      hintText: widget.hint,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          maxLines: widget.maxLines,
          obscureText: widget.obscureText,
          decoration: effectiveDecoration,
          style: widget.style,
        ),
        widget.field.errorAtom.watch((context, error) {
          if (error == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              error,
              style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 12),
            ),
          );
        }),
      ],
    );
  }
}

/// A generic builder widget for any input that binds to a [FieldAtom<T>].
///
/// Useful for Checkboxes, Switches, Radio buttons, or custom sliders.
class NanoField<T> extends StatelessWidget {
  final FieldAtom<T> field;
  final Widget Function(BuildContext context, T value, FieldAtom<T> field)
      builder;

  const NanoField({super.key, required this.field, required this.builder});

  @override
  Widget build(BuildContext context) {
    return field.watch((context, value) => builder(context, value, field));
  }
}

/// Extensions for [FieldAtom] to create reactive fields.
extension FieldAtomReactiveExtension on FieldAtom<String> {
  /// Returns a [NanoTextField] bound to this field.
  Widget textField({
    String? label,
    String? hint,
    int maxLines = 1,
    bool obscureText = false,
    InputDecoration? decoration,
    TextStyle? style,
  }) {
    return NanoTextField(
      field: this,
      label: label,
      hint: hint,
      maxLines: maxLines,
      obscureText: obscureText,
      decoration: decoration,
      style: style,
    );
  }
}

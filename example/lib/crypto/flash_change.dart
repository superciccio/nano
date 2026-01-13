import 'package:flutter/material.dart';

class FlashChange extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Color flashColor;

  const FlashChange({
    super.key,
    required this.text,
    this.style,
    this.flashColor = Colors.green,
  });

  @override
  State<FlashChange> createState() => _FlashChangeState();
}

class _FlashChangeState extends State<FlashChange>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _colorAnimation = ColorTween(
      begin: widget.style?.color,
      end: widget.flashColor,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(FlashChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, _) {
        return Text(
          widget.text,
          style: (widget.style ?? const TextStyle()).copyWith(
            color: _controller.isAnimating
                ? _colorAnimation.value
                : widget.style?.color,
          ),
        );
      },
    );
  }
}

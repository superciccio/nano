import 'package:flutter/widgets.dart';

/// A utility widget that tracks how many times it has been built.
///
/// Use this in tests or debug builds to verify "Surgical Updates" and performance.
///
/// Example:
/// ```dart
/// int rebuilds = 0;
/// await tester.pumpWidget(
///   NanoBuildSpy(
///     label: "MyWidget",
///     onBuild: (count) => rebuilds = count,
///     child: MyWidget(),
///   ),
/// );
/// ```
class NanoBuildSpy extends StatefulWidget {
  final Widget child;
  final ValueChanged<int>? onBuild;
  final String? label;

  const NanoBuildSpy({
    super.key,
    required this.child,
    this.onBuild,
    this.label,
  });

  @override
  State<NanoBuildSpy> createState() => _NanoBuildSpyState();
}

class _NanoBuildSpyState extends State<NanoBuildSpy> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    _count++;

    // Defer callback to avoid potential build-phase state modification issues
    if (widget.onBuild != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onBuild!(_count);
      });
    }

    if (widget.label != null) {
      debugPrint('?? NANO SPY [${widget.label}]: Build #$_count');
    }

    return widget.child;
  }
}

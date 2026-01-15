import 'package:flutter/material.dart';

/// Configuration for [NanoStack] layout.
///
/// **Nano Compose Philosophy:**
/// Instead of nesting `Padding(Child: Column(children: [SizedBox(height: 10), ...]))`,
/// define your layout properties once in [NanoLayout] and let [NanoStack] handle the boilerplate.
///
/// **Usage:**
/// ```dart
/// NanoStack(
///   layout: NanoLayout(
///     padding: EdgeInsets.all(16),
///     spacing: 8, // Adds 8px gap between all children
///     scrollable: true, // Wraps in SingleChildScrollView
///   ),
///   children: [ ... ],
/// )
/// ```
class NanoLayout {
  /// Padding around the entire stack.
  final EdgeInsetsGeometry? padding;

  /// Gap to insert between every child.
  final double spacing;

  /// If true, wraps the column in a [SingleChildScrollView].
  final bool scrollable;

  /// Horizontal alignment of children.
  final CrossAxisAlignment crossAxisAlignment;

  /// Vertical alignment of children.
  final MainAxisAlignment mainAxisAlignment;

  const NanoLayout({
    this.padding,
    this.spacing = 0,
    this.scrollable = false,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  /// Shorthand constructor for uniform padding.
  factory NanoLayout.all(
    double value, {
    double spacing = 0,
    bool scrollable = false,
  }) =>
      NanoLayout(
        padding: EdgeInsets.all(value),
        spacing: spacing,
        scrollable: scrollable,
      );
}

/// A smart container that applies [NanoLayout] properties to its [children].
///
/// It auto-inserts `SizedBox` gaps for [NanoLayout.spacing] and wraps the content
/// in [Padding] or [SingleChildScrollView] as needed.
///
/// **Example:**
/// ```dart
/// NanoStack(
///   layout: NanoLayout.all(16, spacing: 8),
///   children: [
///     Text('Header'),
///     Text('Body'), // 8px gap above
///   ],
/// )
/// ```
class NanoStack extends StatelessWidget {
  final NanoLayout layout;
  final List<Widget> children;

  const NanoStack(
      {super.key, this.layout = const NanoLayout(), required this.children});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (layout.spacing > 0 && i < children.length - 1) {
        items.add(SizedBox(height: layout.spacing));
      }
    }

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: layout.crossAxisAlignment,
      mainAxisAlignment: layout.mainAxisAlignment,
      children: items,
    );

    if (layout.padding != null) {
      content = Padding(padding: layout.padding!, child: content);
    }

    if (layout.scrollable) {
      content = SingleChildScrollView(child: content);
    }

    return content;
  }
}

/// A standard screen layout that reduces [Scaffold] boilerplate.
class NanoPage extends StatelessWidget {
  final dynamic title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const NanoPage({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title != null
          ? AppBar(
              title: title is String
                  ? Text(
                      title!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  : title as Widget,
              centerTitle: false,
              actions: actions,
            )
          : null,
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

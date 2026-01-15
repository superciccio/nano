import 'package:flutter/material.dart';

/// Configuration for [NanoStack] layout.
class NanoLayout {
  final EdgeInsetsGeometry? padding;
  final double spacing;
  final bool scrollable;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;

  const NanoLayout({
    this.padding,
    this.spacing = 0,
    this.scrollable = false,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  /// Shorthand for uniform padding.
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
/// It auto-inserts gaps for [NanoLayout.spacing] and wraps the content
/// in [Padding] or [SingleChildScrollView] as needed.
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

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A simple stateful widget that holds a TextField.
/// This mimics the behavior of NanoTextField or any input widget.
class SimpleInput extends StatefulWidget {
  final String label;
  const SimpleInput({super.key, required this.label});

  @override
  State<SimpleInput> createState() => _SimpleInputState();
}

class _SimpleInputState extends State<SimpleInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.label);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(labelText: widget.label),
      ),
    );
  }
}

void main() {
  testWidgets('DEMO: Reordering WITHOUT Keys loses focus tracking',
      (tester) async {
    // 1. Initial Order: [A, B]
    // We use a ValueNotifier to simulate state changes triggered by "Logic"
    final listOrder = ValueNotifier<List<String>>(['A', 'B']);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<List<String>>(
            valueListenable: listOrder,
            builder: (context, items, _) {
              return Column(
                children: items.map((item) {
                  // CRITICAL: NO KEY HERE
                  return SimpleInput(label: item);
                }).toList(),
              );
            },
          ),
        ),
      ),
    );

    // Helper to find TextField by Index
    Finder findInputAtIndex(int index) {
      return find.descendant(
        of: find.byType(SimpleInput).at(index),
        matching: find.byType(TextField),
      );
    }

    void checkFocus(Finder input, bool shouldHaveFocus, String reason) {
      final editable =
          find.descendant(of: input, matching: find.byType(EditableText));
      final hasFocus =
          tester.state<EditableTextState>(editable).renderEditable.hasFocus;
      expect(hasFocus, shouldHaveFocus, reason: reason);
    }

    // 2. Focus the first item (A)
    // We expect A to be at index 0 initially
    final inputAt0 = findInputAtIndex(0);
    await tester.tap(inputAt0);
    await tester.pump();

    // Verify A is focused
    checkFocus(inputAt0, true, "First item (A) at index 0 has focus");

    // 3. Reorder: [B, A]
    listOrder.value = ['B', 'A'];
    await tester.pumpAndSettle();

    // 4. Verify Focus stayed at Index 0 (which is now B)
    // In No-Key land, the FocusNode stays with the Element at Index 0.
    final inputAt0NowB = findInputAtIndex(0);
    checkFocus(inputAt0NowB, true,
        "WITHOUT KEYS: Focus stayed at index 0 (now B). Focus was 'stolen'.");

    // Check that Index 1 (now A) lost focus
    final inputAt1NowA = findInputAtIndex(1);
    checkFocus(inputAt1NowA, false,
        "WITHOUT KEYS: Item 'A' moved to index 1 and lost focus.");

    // ✅ DEMO PASS: Proved that without keys, focus doesn't follow the item.
  });

  testWidgets('DEMO: Reordering WITH Keys preserves focus', (tester) async {
    // 1. Initial Order: [A, B]
    final listOrder = ValueNotifier<List<String>>(['A', 'B']);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<List<String>>(
            valueListenable: listOrder,
            builder: (context, items, _) {
              return Column(
                children: items.map((item) {
                  // CRITICAL: USING VALUE KEY
                  return SimpleInput(key: ValueKey(item), label: item);
                }).toList(),
              );
            },
          ),
        ),
      ),
    );

    // Helper to find TextField by Label
    Finder findInput(String label) {
      return find.descendant(
        of: find.widgetWithText(SimpleInput, label),
        matching: find.byType(TextField),
      );
    }

    void checkFocus(Finder input, bool shouldHaveFocus, String reason) {
      final editable =
          find.descendant(of: input, matching: find.byType(EditableText));
      final hasFocus =
          tester.state<EditableTextState>(editable).renderEditable.hasFocus;
      expect(hasFocus, shouldHaveFocus, reason: reason);
    }

    // 2. Focus the first item (A)
    final inputA = findInput('A');
    await tester.tap(inputA);
    await tester.pump();

    checkFocus(inputA, true, "First item (A) has focus");

    // 3. Reorder: [B, A]
    listOrder.value = ['B', 'A'];
    await tester.pumpAndSettle();

    // 4. Verify Focus followed 'A' to Index 1
    // Flutter saw the Key move, so it moved the Element+State+FocusNode to index 1.

    final inputAMoved = findInput('A');
    checkFocus(inputAMoved, true,
        "WITH KEYS: Focus correctly followed Item A to its new position.");

    // Verify 'B' (at index 0) is NOT focused
    final inputB = findInput('B');
    checkFocus(inputB, false, "Item B should not look focused");

    // ✅ DEMO PASS: Proved that WITH keys, focus tracks the item correctly.
  });
}

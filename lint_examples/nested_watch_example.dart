import 'package:flutter/widgets.dart';
import 'package:nano/nano.dart';

void testNestedWatch() {
  final atom1 = 0.toAtom();
  final atom2 = 'foo'.toAtom();

  Watch(
    atom1,
    builder: (context, v1) {
      // expect_lint: avoid_nested_watch
      return Watch(
        atom2,
        builder: (context, v2) {
          return Text('$v1 $v2', textDirection: TextDirection.ltr);
        },
      );
    },
  );

  atom1.watch((context, v1) {
    // expect_lint: avoid_nested_watch
    return atom2.watch((context, v2) {
      return Text('$v1 $v2', textDirection: TextDirection.ltr);
    });
  });

  // This should not lint (Tuple Syntax)
  // (atom1, atom2).watch((context, v1, v2) {
  //   return Text('$v1 $v2');
  // });
}

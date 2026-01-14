import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

class Service {
  final String name;
  Service(this.name);
}

void main() {
  testWidgets('Scope should update Registry when modules change',
      (tester) async {
    final serviceA = Service('A');
    final serviceB = Service('B');

    Widget buildScope(Service service) {
      return Scope(
        modules: [service],
        child: Builder(
          builder: (context) {
            final s = context.read<Service>();
            return Text(s.name);
          },
        ),
      );
    }

    await tester.pumpWidget(MaterialApp(home: buildScope(serviceA)));
    expect(find.text('A'), findsOneWidget);

    // Update with service B
    await tester.pumpWidget(MaterialApp(home: buildScope(serviceB)));

    // This is expected to FAIL currently because Scope doesn't update registry
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('Scope should update Registry when NanoLazy changes',
      (tester) async {
    int creations = 0;

    Widget buildScope(String name) {
      return Scope(
        modules: [
          NanoLazy((r) {
            creations++;
            return Service(name);
          }),
        ],
        child: Builder(
          builder: (context) {
            final s = context.read<Service>();
            return Text(s.name);
          },
        ),
      );
    }

    await tester.pumpWidget(MaterialApp(home: buildScope('A')));
    expect(find.text('A'), findsOneWidget);
    expect(creations, 1);

    // Update with service B
    await tester.pumpWidget(MaterialApp(home: buildScope('B')));

    // This is expected to FAIL: it should find 'B' and creations should be 2
    expect(find.text('B'), findsOneWidget);
    expect(creations, 2);
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';
import 'dart:async';

void main() {
  group('Evolution: Smart Computeds', () {
    test('computed() helper should track dependencies automatically', () {
      final a = Atom(1, label: 'a');
      final b = Atom(2, label: 'b');
      final c = computed(() => a.value + b.value, label: 'c');

      // It's lazy, so value is computed only on access
      expect(c.value, 3);

      a.value = 10;
      expect(c.value, 12);

      b.value = 20;
      expect(c.value, 30);
    });

    test('computed() should be lazy (only tracks when active)', () {
      int computations = 0;
      final a = Atom(1);
      final c = computed(() {
        computations++;
        return a.value * 2;
      });

      expect(computations, 1); // Computed once in constructor

      final val = c.value; // Read once
      expect(val, 2);
      expect(computations,
          1); // CACHED: Nano.version hasn't changed since constructor

      a.value = 5;
      expect(computations, 1); // Still 1 because nobody is listening (inactive)

      expect(c.value, 10);
      expect(computations,
          2); // Re-computed on access because it was stale (Nano.version bumped)
    });
  });

  group('Evolution: Scoped Reactions', () {
    test('NanoLogic auto() should dispose with logic', () {
      int runs = 0;
      final atom = Atom(0);
      final logic = _TestLogic();
      logic.initialize(null);

      logic.auto(() {
        atom.value;
        runs++;
      });

      expect(runs, 1);
      atom.value = 1;
      expect(runs, 2);

      logic.dispose();
      atom.value = 2;
      expect(runs, 2); // Should not run after dispose
    });
  });

  group('Evolution: Action Middleware', () {
    test('Named actions and middleware integration', () {
      final logs = <String>[];
      final middleware = _TestMiddleware((s) => logs.add(s));
      final config = NanoConfig(middlewares: [middleware]);

      runZoned(() {
        Nano.action('UpdateProfile', () {
          // ...
        });
      }, zoneValues: {#nanoConfig: config});

      expect(logs, ['start:UpdateProfile', 'end:UpdateProfile']);
    });
  });

  group('Evolution: NanoView improvements', () {
    testWidgets('rebuildOnUpdate: false should avoid coarse rebuilds',
        (tester) async {
      int rootBuilds = 0;
      int surgicalBuilds = 0;

      final logic = _RebuildLogic();
      logic.initialize(null);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Scope(
            modules: [],
            child: NanoView<_RebuildLogic, void>(
              create: (_) => logic,
              rebuildOnUpdate: false,
              builder: (context, logic) {
                rootBuilds++;
                return Watch(logic.counter, builder: (context, val) {
                  surgicalBuilds++;
                  return Text('Count: $val');
                });
              },
            ),
          ),
        ),
      );

      expect(rootBuilds, 1);
      expect(surgicalBuilds, 1);

      // Trigger logic notification (coarse)
      logic.notifyListeners();
      await tester.pump();

      expect(rootBuilds, 1); // Should NOT rebuild root
      expect(surgicalBuilds, 1);

      // Trigger atom update (surgical)
      logic.counter.value++;
      await tester.pump();

      expect(rootBuilds, 1);
      expect(surgicalBuilds, 2); // ONLY surgical watch rebuilt
    });
  });
}

class _TestLogic extends NanoLogic<void> {}

class _RebuildLogic extends NanoLogic<void> {
  final counter = Atom(0);
}

class _TestMiddleware implements NanoMiddleware {
  final Function(String) onLog;
  _TestMiddleware(this.onLog);

  @override
  void onActionStart(String name) => onLog('start:$name');

  @override
  void onActionEnd(String name) => onLog('end:$name');
}

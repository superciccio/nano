import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

class TestLogic extends NanoLogic {
  bool disposed = false;
  
  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

class ParentService {
  final String name = 'Parent';
}

class TestComponent extends NanoComponent {
  final List<Object> overrideModules;
  
  const TestComponent({super.key, this.overrideModules = const []});

  @override
  List<Object> get modules => [
    if (overrideModules.isEmpty) NanoLazy((_) => TestLogic())
    else ...overrideModules
  ];

  @override
  Widget view(BuildContext context) {
    final logic = context.use<TestLogic>();
    final parent = context.use<ParentService>();
    return Text('Logic: ${logic.hashCode}, Parent: ${parent.name}');
  }
}

void main() {
  group('NanoComponent Hardening', () {
    testWidgets('Resolves local logic and parent services', (tester) async {
      await tester.pumpWidget(
        Scope(
          modules: [ParentService()],
          child: const MaterialApp(
            home: TestComponent(),
          ),
        ),
      );

      expect(find.textContaining('Logic:'), findsOneWidget);
      expect(find.textContaining('Parent: Parent'), findsOneWidget);
    });

    testWidgets('Each instance has isolated state', (tester) async {
      await tester.pumpWidget(
        Scope(
          modules: [ParentService()],
          child: const MaterialApp(
            home: Column(
              children: [
                TestComponent(key: Key('A')),
                TestComponent(key: Key('B')),
              ],
            ),
          ),
        ),
      );

      final textA = tester.widget<Text>(find.descendant(of: find.byKey(const Key('A')), matching: find.byType(Text)));
      final textB = tester.widget<Text>(find.descendant(of: find.byKey(const Key('B')), matching: find.byType(Text)));
      
      // Hashcodes should be different
      expect(textA.data, isNot(textB.data));
    });

    testWidgets('Disposes logic when component is removed', (tester) async {
      bool showComponent = true;
      late TestLogic logicInstance;

      await tester.pumpWidget(
        Scope(
          modules: [ParentService()],
          child: MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    if (showComponent) TestComponent(
                      overrideModules: [
                        NanoLazy((r) {
                          logicInstance = TestLogic();
                          return logicInstance;
                        })
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => showComponent = false),
                      child: const Text('Remove'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Trigger lazy creation
      await tester.pump(); 
      expect(logicInstance.disposed, isFalse);

      // Remove component
      await tester.tap(find.text('Remove'));
      await tester.pump();

      expect(logicInstance.disposed, isTrue);
    });

    testWidgets('Re-registers when modules list changes', (tester) async {
      int creations = 0;
      
      await tester.pumpWidget(
        Scope(
          modules: [ParentService()],
          child: MaterialApp(
            home: TestComponent(
              overrideModules: [
                NanoLazy((r) {
                  creations++;
                  return TestLogic();
                })
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      expect(creations, 1);

      // Update widget with new module list identity
      await tester.pumpWidget(
        Scope(
          modules: [ParentService()],
          child: MaterialApp(
            home: TestComponent(
              overrideModules: [
                NanoLazy((r) {
                  creations++;
                  return TestLogic();
                })
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      // Should have re-registered and re-created because modules list changed
      expect(creations, 2);
    });
  });
}

extension FinderExt on Finder {
  Finder descendant({required Finder of}) => find.descendant(of: of, matching: this);
}

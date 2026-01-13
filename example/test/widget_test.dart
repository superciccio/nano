import 'package:flutter_test/flutter_test.dart';
import 'package:nano_example/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('Nano Examples Showcase'), findsOneWidget);
    expect(find.text('Counter & Computed'), findsOneWidget);
  });
}

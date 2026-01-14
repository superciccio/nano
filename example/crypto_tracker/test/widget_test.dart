import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_tracker/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('Nano Examples Showcase'), findsOneWidget);
    expect(find.text('Live Crypto Ticker'), findsOneWidget);
  });
}

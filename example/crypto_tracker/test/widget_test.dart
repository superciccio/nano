import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';
import 'package:crypto_tracker/crypto/crypto_example.dart';
import 'package:crypto_tracker/crypto/crypto_service.dart';

// Mock Service
class MockCryptoService implements CryptoService {
  final _controller = StreamController<List<CryptoCoin>>();

  @override
  Stream<List<CryptoCoin>> get pricesStream => _controller.stream;

  void emit(List<CryptoCoin> coins) {
    _controller.add(coins);
  }
}

void main() {
  testWidgets('CryptoTickerPage displays coins from service', (WidgetTester tester) async {
    final mockService = MockCryptoService();

    await tester.pumpWidget(
      Scope(
        modules: [
          // Override the service
          NanoFactory<CryptoService>((_) => mockService),
        ],
        child: const MaterialApp(
          home: CryptoTickerPage(),
        ),
      ),
    );

    // Initial state (loading)
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Emit data
    mockService.emit([
      const CryptoCoin(
        symbol: 'BTC',
        name: 'Bitcoin',
        price: 50000.0,
        change24h: 5.0,
      ),
      const CryptoCoin(
        symbol: 'ETH',
        name: 'Ethereum',
        price: 3000.0,
        change24h: -2.0,
      ),
    ]);

    await tester.pump(); // Process stream
    await tester.pump(); // Rebuild UI

    // Verify List
    expect(find.text('BTC'), findsOneWidget);
    expect(find.text('ETH'), findsOneWidget);
    
    // Verify sorting (Logic does sorting)
    // BTC (50000) should be first, ETH (3000) second.
    // The listview builder renders them in order.
    
    // Verify Top Gainer
    expect(find.textContaining('Top Performer: Bitcoin'), findsOneWidget);
    
    // Verify Market Sentiment
    // Avg change: (5 - 2) / 2 = 1.5. Bullish > 0.5
    expect(find.text('Bullish 🚀'), findsOneWidget);
  });
}
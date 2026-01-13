import 'dart:async';
import 'dart:math';

class CryptoCoin {
  final String symbol;
  final String name;
  final double price;
  final double change24h;

  const CryptoCoin({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change24h,
  });

  CryptoCoin copyWith({double? price, double? change24h}) {
    return CryptoCoin(
      symbol: symbol,
      name: name,
      price: price ?? this.price,
      change24h: change24h ?? this.change24h,
    );
  }
}

class CryptoService {
  final _random = Random();
  final List<CryptoCoin> _initialCoins = [
    const CryptoCoin(
      symbol: 'BTC',
      name: 'Bitcoin',
      price: 65430.00,
      change24h: 2.5,
    ),
    const CryptoCoin(
      symbol: 'ETH',
      name: 'Ethereum',
      price: 3450.00,
      change24h: 1.2,
    ),
    const CryptoCoin(
      symbol: 'SOL',
      name: 'Solana',
      price: 145.00,
      change24h: -5.4,
    ),
    const CryptoCoin(
      symbol: 'XRP',
      name: 'Ripple',
      price: 0.62,
      change24h: 0.8,
    ),
    const CryptoCoin(
      symbol: 'DOGE',
      name: 'Dogecoin',
      price: 0.12,
      change24h: 12.5,
    ),
    const CryptoCoin(
      symbol: 'ADA',
      name: 'Cardano',
      price: 0.45,
      change24h: -1.1,
    ),
    const CryptoCoin(
      symbol: 'DOT',
      name: 'Polkadot',
      price: 7.20,
      change24h: -0.5,
    ),
    const CryptoCoin(
      symbol: 'LINK',
      name: 'Chainlink',
      price: 14.50,
      change24h: 3.2,
    ),
  ];

  Stream<List<CryptoCoin>> get pricesStream async* {
    var currentCoins = List<CryptoCoin>.from(_initialCoins);

    // Simulate initial delay
    await Future.delayed(const Duration(seconds: 1));
    yield currentCoins;

    // Simulate live updates
    while (true) {
      await Future.delayed(const Duration(milliseconds: 200)); // Fast updates!

      // Update 1-3 random coins
      final updatesCount = _random.nextInt(3) + 1;
      final newCoins = List<CryptoCoin>.from(currentCoins);

      for (var i = 0; i < updatesCount; i++) {
        final index = _random.nextInt(newCoins.length);
        final coin = newCoins[index];

        final priceChange = (coin.price * 0.005) * (_random.nextDouble() - 0.5);
        final newPrice = coin.price + priceChange;
        final newChange = coin.change24h + (_random.nextDouble() - 0.5);

        newCoins[index] = coin.copyWith(price: newPrice, change24h: newChange);
      }

      currentCoins = newCoins;
      yield currentCoins;
    }
  }
}

import 'package:nano/nano.dart';
import 'crypto_service.dart';

class CryptoLogic extends NanoLogic<void> {
  final CryptoService _service;
  CryptoLogic(this._service);

  // 1. The Core Data source
  final coins = Atom<List<CryptoCoin>>([], label: 'coins');

  // 2. Computed: Sort by price high to low
  late final sortedCoins = ComputedAtom([coins], () {
    final list = List<CryptoCoin>.from(coins.value);
    list.sort((a, b) => b.price.compareTo(a.price));
    return list;
  }, label: 'sortedCoins');

  // 3. Computed: Top Gainer (Best performance)
  late final topGainer = ComputedAtom([coins], () {
    if (coins.value.isEmpty) return null;
    return coins.value.reduce(
      (curr, next) => curr.change24h > next.change24h ? curr : next,
    );
  }, label: 'topGainer');

  // 4. Computed: Market Status (Bull vs Bear)
  late final marketSentiment = ComputedAtom([coins], () {
    if (coins.value.isEmpty) return 'Neutral';
    final avgChange =
        coins.value.fold(0.0, (sum, c) => sum + c.change24h) /
        coins.value.length;
    if (avgChange > 0.5) return 'Bullish 🚀';
    if (avgChange < -0.5) return 'Bearish 🐻';
    return 'Neutral 😐';
  }, label: 'marketSentiment');

  @override
  void onInit(void params) {
    // Automatically bind the stream to the atom.
    // Nano handles subscription and disposal.
    bindStream(_service.pricesStream, coins);
  }
}

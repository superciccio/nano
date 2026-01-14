import 'package:flutter/material.dart';
import 'package:nano/nano.dart';
import 'crypto_logic.dart';
import 'crypto_service.dart';
import 'flash_change.dart';

class CryptoTickerPage extends StatelessWidget {
  const CryptoTickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    // NanoView handles creating the logic and the scope
    return NanoView<CryptoLogic, void>(
      create: (reg) => CryptoLogic(reg.get()),
      rebuildOnUpdate: false,
      builder: (context, logic) {
        return Scaffold(
          backgroundColor: const Color(0xFF0F172A), // Dark Navy
          appBar: AppBar(
            title: const Text('Crypto Live Ticker'),
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: logic.marketSentiment.watch((context, sentiment) {
                    return Text(
                      sentiment,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    );
                  }),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Top Gainer Banner
              logic.topGainer.watch((context, coin) {
                if (coin == null) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.trending_up, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Top Performer: ${coin.name} (${coin.change24h.toStringAsFixed(2)}%)',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // List of Coins
              Expanded(
                child: logic.sortedCoins.watch((context, coins) {
                  if (coins.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ListView.builder(
                    itemCount: coins.length,
                    itemBuilder: (context, index) {
                      final coin = coins[index];
                      // Note: In a real app with huge lists, we might want to wrap each
                      // list item in its own SelectorAtom for extreme performance,
                      // but here we are rebuilding the list on every update
                      // to show that even that is fast, but individual Text widgets handle the "flash".
                      return _CoinRow(coin: coin, index: index);
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CoinRow extends StatelessWidget {
  final CryptoCoin coin;
  final int index;

  const _CoinRow({required this.coin, required this.index});

  @override
  Widget build(BuildContext context) {
    final isPositive = coin.change24h >= 0;
    final color = isPositive ? Colors.greenAccent : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#${index + 1}',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coin.symbol,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  coin.name,
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FlashChange(
                text: '\$${coin.price.toStringAsFixed(2)}',
                flashColor: color,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              FlashChange(
                text:
                    '${isPositive ? '+' : ''}${coin.change24h.toStringAsFixed(2)}%',
                flashColor: color,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

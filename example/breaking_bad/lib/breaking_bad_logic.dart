import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nano/nano.dart';

// -----------------------------------------------------------------------------
// Service
// -----------------------------------------------------------------------------
class QuoteService {
  Future<Quote> fetchQuote() async {
    final response = await http.get(Uri.parse('https://api.breakingbadquotes.xyz/v1/quotes'));
    final data = json.decode(response.body) as List;

    if (data.isNotEmpty) {
      final q = data[0];
      return Quote(
        quote: q['quote'],
        author: q['author'],
      );
    }
    throw 'No quotes found';
  }
}

// -----------------------------------------------------------------------------
// Models
// -----------------------------------------------------------------------------
class Quote {
  final String quote;
  final String author;
  Quote({required this.quote, required this.author});
}

// -----------------------------------------------------------------------------
// Logic
// -----------------------------------------------------------------------------
class StatsLogic extends NanoLogic<void> {
  // Singleton removed! Managed by Scope.

  final saulCount = Atom<int>(0, label: 'Saul Count');
  final jesseCount = Atom<int>(0, label: 'Jesse Count');
  final waltCount = Atom<int>(0, label: 'Walt Count');
  final totalQuotes = Atom<int>(0, label: 'Total Quotes');

  void increment(String author) {
    totalQuotes.update((v) => v + 1);

    if (author.contains('Saul')) {
      saulCount.update((v) => v + 1);
    } else if (author.contains('Jesse')) {
      jesseCount.update((v) => v + 1);
    } else if (author.contains('Walter') || author.contains('Heisenberg')) {
      waltCount.update((v) => v + 1);
    }
  }
}

class QuoteLogic extends NanoLogic<void> {
  final QuoteService _service;
  final StatsLogic _statsLogic;

  QuoteLogic(this._service, this._statsLogic);

  final quote = AsyncAtom<Quote>(label: 'quote');

  Future<void> fetchQuote() async {
    await quote.track(() async {
      final newQuote = await _service.fetchQuote();
      _statsLogic.increment(newQuote.author);
      return newQuote;
    }());
  }
}
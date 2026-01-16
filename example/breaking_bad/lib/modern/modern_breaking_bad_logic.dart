// ignore_for_file: library_private_types_in_public_api

import 'package:nano/nano.dart';
import 'package:nano_annotations/nano_annotations.dart';
import '../breaking_bad_logic.dart'; // For QuoteService, Quote

part 'modern_breaking_bad_logic.g.dart';

@nano
abstract class _ModernStatsLogic extends NanoLogic {
  @state int saulCount = 0;
  @state int jesseCount = 0;
  @state int waltCount = 0;
  @state int totalQuotes = 0;

  void increment(String author) {
    totalQuotes++;
    if (author.contains('Saul')) {
      saulCount++;
    } else if (author.contains('Jesse')) {
      jesseCount++;
    } else if (author.contains('Walter') || author.contains('Heisenberg')) {
      waltCount++;
    }
  }
}

class ModernStatsLogic = _ModernStatsLogic with _$ModernStatsLogic;

@nano
abstract class _ModernQuoteLogic extends NanoLogic {
  final QuoteService _service;
  final ModernStatsLogic _statsLogic;

  _ModernQuoteLogic(this._service, this._statsLogic);

  // Manual AsyncAtom because generator handles @state <T> as Atom<T>.
  // We want AsyncAtom<Quote> for async state management.
  late final quote = AsyncAtom<Quote>(label: 'quote');

  Future<void> fetchQuote() async {
    await quote.track(() async {
      final newQuote = await _service.fetchQuote();
      _statsLogic.increment(newQuote.author);
      return newQuote;
    }());
  }
}

class ModernQuoteLogic extends _ModernQuoteLogic with _$ModernQuoteLogic {
  ModernQuoteLogic(super.service, super.statsLogic);
}

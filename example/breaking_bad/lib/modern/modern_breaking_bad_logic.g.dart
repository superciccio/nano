// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modern_breaking_bad_logic.dart';

// **************************************************************************
// NanoGenerator
// **************************************************************************

mixin _$ModernStatsLogic on _ModernStatsLogic {
  late final _$saulCountAtom =
      Atom<int>(super.saulCount, label: 'ModernStatsLogic.saulCount');
  @override
  int get saulCount => _$saulCountAtom.value;
  @override
  set saulCount(int value) {
    super.saulCount = value;
    _$saulCountAtom.value = value;
  }

  Atom<int> get saulCount$ => _$saulCountAtom;
  late final _$jesseCountAtom =
      Atom<int>(super.jesseCount, label: 'ModernStatsLogic.jesseCount');
  @override
  int get jesseCount => _$jesseCountAtom.value;
  @override
  set jesseCount(int value) {
    super.jesseCount = value;
    _$jesseCountAtom.value = value;
  }

  Atom<int> get jesseCount$ => _$jesseCountAtom;
  late final _$waltCountAtom =
      Atom<int>(super.waltCount, label: 'ModernStatsLogic.waltCount');
  @override
  int get waltCount => _$waltCountAtom.value;
  @override
  set waltCount(int value) {
    super.waltCount = value;
    _$waltCountAtom.value = value;
  }

  Atom<int> get waltCount$ => _$waltCountAtom;
  late final _$totalQuotesAtom =
      Atom<int>(super.totalQuotes, label: 'ModernStatsLogic.totalQuotes');
  @override
  int get totalQuotes => _$totalQuotesAtom.value;
  @override
  set totalQuotes(int value) {
    super.totalQuotes = value;
    _$totalQuotesAtom.value = value;
  }

  Atom<int> get totalQuotes$ => _$totalQuotesAtom;
}

mixin _$ModernQuoteLogic on _ModernQuoteLogic {
  late final _$quoteAtom =
      AsyncAtom<Quote>(initial: super.quote, label: 'ModernQuoteLogic.quote');
  @override
  AsyncState<Quote> get quote => _$quoteAtom.value;
  @override
  set quote(AsyncState<Quote> value) {
    super.quote = value;
    _$quoteAtom.value = value;
  }

  @override
  AsyncAtom<Quote> get quote$ => _$quoteAtom;
  Future<void> trackQuote(Future<Quote> future) => _$quoteAtom.track(future);
}

part of 'poc_nano_counter.dart';

mixin _$PocCounterLogic on PocCounterLogic {
  late final _count$Atom = Atom<int>(super.count, label: 'PocCounterLogic.count');

  @override
  int get count {
    return _count$Atom.value;
  }

  @override
  set count(int value) {
    _count$Atom.value = value;
  }
}

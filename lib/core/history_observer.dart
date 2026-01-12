import 'package:nano/nano.dart';

final historyObserver = HistoryObserver();

class StateChangeEvent {
  final String label;
  final dynamic oldValue;
  final dynamic newValue;
  final DateTime timestamp;

  StateChangeEvent({
    required this.label,
    required this.oldValue,
    required this.newValue,
    required this.timestamp,
  });
}

class HistoryObserver extends NanoObserver {
  final List<StateChangeEvent> events = [];

  @override
  void onChange(Atom atom, oldValue, newValue) {
    events.add(
      StateChangeEvent(
        label: atom.label ?? atom.runtimeType.toString(),
        oldValue: oldValue,
        newValue: newValue,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void onError(Atom atom, Object error, StackTrace stack) {
    // For now, we don't store errors in the history.
  }
}

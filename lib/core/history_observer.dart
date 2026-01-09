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
  void onChange(String label, oldValue, newValue) {
    events.add(
      StateChangeEvent(
        label: label,
        oldValue: oldValue,
        newValue: newValue,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void onError(String label, Object error, StackTrace stack) {
    // For now, we don't store errors in the history.
  }
}

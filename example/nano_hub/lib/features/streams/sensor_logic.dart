import 'dart:async';
import 'dart:math';
import 'package:nano/nano.dart';

/// A data model for sensor statistics.
class SensorStats {
  final double mean;
  final double max;
  final double min;
  final int count;

  const SensorStats({
    required this.mean,
    required this.max,
    required this.min,
    required this.count,
  });

  @override
  String toString() =>
      "Avg: ${mean.toStringAsFixed(1)} | Max: ${max.toStringAsFixed(1)} | Min: ${min.toStringAsFixed(1)} (N=$count)";
}

class SensorLogic extends NanoLogic<void> {
  /// A stream of simulated temperature readings.
  late final _sensorResource = ResourceAtom<Stream<double>>((ref) {
    final controller = StreamController<double>.broadcast();
    // Reduced frequency to 1 second for a more stable showcase
    final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final value = 20.0 + (Random().nextDouble() * 10.0);
      controller.add(value);
    });

    ref.onDispose(() {
      timer.cancel();
      controller.close();
    });

    return controller.stream;
  }, label: 'sensorResource');

  /// Tracks the most recent sensor reading.
  late final currentReading = StreamAtom<double>(
    _sensorResource.value,
    label: 'currentReading',
  );

  /// Keeping a sliding window of the last 20 readings.
  late final history = currentReading.scan<List<double>>([], (history, state) {
    if (state is AsyncData<double>) {
      final newList = List<double>.from(history)..add(state.data);
      if (newList.length > 20) newList.removeAt(0);
      return newList;
    }
    return history;
  }, label: 'sensorHistory');

  /// Offloads complex statistical computation to a background isolate.
  late final statsWorker = WorkerAtom<List<double>, SensorStats>(
    history,
    _computeStats,
    label: 'statsWorker',
  );

  static SensorStats _computeStats(List<double> data) {
    if (data.isEmpty) {
      return const SensorStats(mean: 0, max: 0, min: 0, count: 0);
    }

    // Simulate complex/heavy math
    final start = DateTime.now();
    while (DateTime.now().difference(start).inMilliseconds < 50) {}

    final sum = data.reduce((a, b) => a + b);
    final max = data.reduce((a, b) => a > b ? a : b);
    final min = data.reduce((a, b) => a < b ? a : b);

    return SensorStats(
      mean: sum / data.length,
      max: max,
      min: min,
      count: data.length,
    );
  }

  @override
  void onInit(void params) {}

  @override
  void onReady() {
    status.value = NanoStatus.success;
  }
}

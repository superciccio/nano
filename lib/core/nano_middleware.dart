import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:nano/core/nano_core.dart';

/// A middleware that record Nano actions in the Flutter DevTools Timeline.
///
/// This allows you to see exactly which Nano action is running in the 
/// Performance view of DevTools, helping you identify performance bottlenecks.
class TimelineMiddleware implements NanoMiddleware {
  @override
  void onActionStart(String name) {
    if (!kDebugMode) return;
    dev.Timeline.startSync('?? NANO: $name');
  }

  @override
  void onActionEnd(String name) {
    if (!kDebugMode) return;
    dev.Timeline.finishSync();
  }
}

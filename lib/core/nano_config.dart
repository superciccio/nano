import 'package:nano/core/nano_core.dart';
import 'package:nano/core/nano_persistence.dart';

class NanoConfig {
  static bool strictMode = false;

  final NanoObserver? observer;
  final List<NanoMiddleware> middlewares;
  final NanoStorage? storage;

  const NanoConfig({
    this.observer,
    this.middlewares = const [],
    this.storage,
  });
}

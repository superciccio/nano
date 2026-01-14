import 'package:nano/nano.dart';

class DeviceLogic extends NanoLogic {
  /// A family of atoms, one for each device ID.
  /// Each atom is created lazily and memoized.
  final deviceStatus = AtomFamily<String, ValueAtom<bool>>(
    (id) => ValueAtom(false, label: 'device_status_$id'),
  );

  void toggleDevice(String id) {
    print("?? EXPLORER: Toggling $id");
    final atom = deviceStatus(id);
    atom.value = !atom.value;
  }

  bool isOnline(String id) => deviceStatus(id).value;

  @override
  void onInit(void params) {
    print("?? EXPLORER: onInit");
  }

  @override
  void onReady() {
    print("?? EXPLORER: onReady");
    status.value = NanoStatus.success;
  }
}

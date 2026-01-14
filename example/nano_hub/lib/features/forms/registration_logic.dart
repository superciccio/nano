import 'package:flutter/foundation.dart';
import 'package:nano/nano.dart';

class RegistrationLogic extends NanoLogic<void> {
  final nameField = FieldAtom<String>(
    '',
    validators: [
      Validators.required<String>(),
      (val) => val.length < 3 ? 'Too short' : null,
    ],
    label: 'name',
  );

  final serialField = FieldAtom<String>(
    '',
    validators: [
      Validators.required<String>(),
      (val) => !RegExp(r'^SN-\d{4}$').hasMatch(val) ? 'Format: SN-1234' : null,
    ],
    label: 'serial',
  );

  late final form = FormAtom([nameField, serialField]);

  void submit() {
    if (form.validate()) {
      // Handle submission
      debugPrint(
        '?? FORMS: Registering: ${nameField.value}, ${serialField.value}',
      );
    }
  }

  void reset() {
    print("?? FORMS: Resetting");
    form.reset();
  }

  @override
  void onInit(void params) {
    print("?? FORMS: onInit");
  }

  @override
  void onReady() {
    print("?? FORMS: onReady");
    status.value = NanoStatus.success;
  }
}

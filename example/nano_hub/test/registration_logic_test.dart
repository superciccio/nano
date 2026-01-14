import 'package:flutter_test/flutter_test.dart';
import 'package:nano/test/nano_matchers.dart';
import 'package:nano_hub/features/forms/registration_logic.dart';

void main() {
  group('RegistrationLogic Tests', () {
    late RegistrationLogic logic;

    setUp(() {
      logic = RegistrationLogic();
    });

    test('Form state requires validation to show initial errors', () {
      // By default, fields are null/empty and error is null until validated
      expect(logic.form.isValid, isTrue);

      logic.form.validate();
      expect(logic.form.isValid, isFalse);
    });

    test('Validation updates error atoms when fields change', () async {
      final nameErrorTester = logic.nameField.errorAtom.tester;

      // We need to validate once to "touch" the field so it validates on subsequent sets
      logic.nameField.validate();
      await nameErrorTester.expect(contains('Required'));

      logic.nameField.set('A'); // Too short
      await nameErrorTester.expect(contains('Too short'));

      logic.nameField.set('Andrea');
      await nameErrorTester.expect(contains(null));
    });

    test('Full form validation', () {
      logic.form.validate();
      expect(logic.form.isValid, isFalse);

      logic.nameField.set('Andrea');
      logic.serialField.set('SN-1234');

      expect(logic.form.isValid, isTrue);
    });

    test('Reset restores initial values and clears errors', () {
      logic.nameField.set('A');
      logic.nameField.validate();
      expect(logic.nameField.error, isNotNull);

      logic.nameField.reset();
      expect(logic.nameField.value, '');
      expect(logic.nameField.error, isNull);
    });
  });
}

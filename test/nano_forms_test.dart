import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';

void main() {
  test('FieldAtom validates on set', () {
    final email = FieldAtom('',
        validators: [Validators.required<String>(), Validators.email()]);

    // Initial state: valid (validators usually don't run until touched or explicit validate)
    // Actually our implementation init error is null.
    expect(email.isValid, true);
    expect(email.error, null);

    // Set invalid
    email.value = 'invalid-email';
    // touched defaults to false, so set() doesn't auto-validate unless touched.
    // Let's validate explicitly first
    email.validate();

    expect(email.isValid, false);
    expect(email.error, 'Invalid email');

    // Now touched is true, set() should auto-validate
    email.value = 'valid@email.com';
    expect(email.isValid, true);
    expect(email.error, null);
  });

  test('FormAtom aggregates validity', () {
    final f1 = FieldAtom('a', validators: [Validators.required<String>()]);
    final f2 = FieldAtom('b', validators: [Validators.required<String>()]);
    final form = FormAtom([f1, f2]);

    expect(form.isValid, true);

    f1.value = ''; // Empty string
    f1.validate();

    expect(f1.isValid, false);
    expect(form.isValid, false);

    f1.value = 'ok'; // Auto-validates because touched
    expect(form.isValid, true);
  });
}

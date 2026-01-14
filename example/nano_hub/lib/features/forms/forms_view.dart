import 'package:flutter/material.dart';
import 'package:nano/nano.dart';
import 'package:nano_hub/core/theme.dart';
import 'package:nano_hub/features/forms/registration_logic.dart';

class RegistrationView extends NanoView<RegistrationLogic, void> {
  RegistrationView({super.key})
    : super(
        create: (reg) => RegistrationLogic(),
        builder: (context, logic) => _build(context, logic),
      );

  static Widget _build(BuildContext context, RegistrationLogic logic) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Registration'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              NanoHubTheme.backgroundColor,
              Colors.orange.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
          children: [
            const Text(
              'NEW DEVICE SETUP',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: NanoHubTheme.glassDecoration(opacity: 0.03),
              child: Column(
                children: [
                  _FormField(
                    label: 'Device Name',
                    hint: 'e.g. Living Room Sensor',
                    onChanged: (v) => logic.nameField.set(v),
                    errorAtom: logic.nameField.errorAtom,
                  ),
                  const SizedBox(height: 20),
                  _FormField(
                    label: 'Serial Number',
                    hint: 'SN-1234',
                    onChanged: (v) => logic.serialField.set(v),
                    errorAtom: logic.serialField.errorAtom,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: logic.form.isValidAtom.watch((context, isValid) {
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isValid
                              ? NanoHubTheme.primaryColor
                              : Colors.white10,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isValid ? logic.submit : null,
                        child: const Text('REGISTER DEVICE'),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final String hint;
  final ValueChanged<String> onChanged;
  final Atom<String?> errorAtom;

  const _FormField({
    required this.label,
    required this.hint,
    required this.onChanged,
    required this.errorAtom,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
            filled: true,
            fillColor: Colors.black26,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        errorAtom.watch((context, error) {
          if (error == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              error,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          );
        }),
      ],
    );
  }
}

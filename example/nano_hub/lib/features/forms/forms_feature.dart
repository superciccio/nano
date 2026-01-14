import 'package:flutter/material.dart';
import 'package:nano_hub/core/demo_registry.dart';
import 'package:nano_hub/features/forms/forms_view.dart';

class FormsFeature {
  static void register() {
    DemoRegistry.register(
      DemoModule(
        id: 'forms',
        title: 'Nano Forms',
        description: 'Reactive form validation & state.',
        icon: Icons.edit_note_outlined,
        builder: RegistrationView(),
        version: 'v0.7.0',
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:nano/nano.dart';
import 'package:nano_hub/core/theme.dart';
import 'package:nano_hub/features/explorer/explorer_logic.dart';

class ExplorerView extends NanoView<DeviceLogic, void> {
  ExplorerView({super.key})
    : super(
        create: (reg) => DeviceLogic(),
        builder: (context, logic) => _build(context, logic),
      );

  static Widget _build(BuildContext context, DeviceLogic logic) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Explorer'),
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
              Colors.blue.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
          itemCount: 50, // Demonstrate many items
          itemBuilder: (context, index) {
            final id = 'DEV-${(index + 100).toString()}';
            // We bind to the specific atom in the family
            return logic.deviceStatus(id).watch((context, isOnline) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: NanoHubTheme.glassDecoration(opacity: 0.03),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    title: Text(
                      id,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      isOnline ? 'System Online' : 'System Standby',
                      style: TextStyle(
                        color: isOnline ? Colors.greenAccent : Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Switch(
                      value: isOnline,
                      activeThumbColor: NanoHubTheme.accentColor,
                      onChanged: (_) => logic.toggleDevice(id),
                    ),
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }
}

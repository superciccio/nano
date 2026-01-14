import 'package:flutter/material.dart';
import 'package:nano/nano.dart';
import 'package:nano_hub/core/theme.dart';
import 'package:nano_hub/features/persistence/settings_logic.dart';

class SettingsView extends NanoView<SettingsLogic, void> {
  SettingsView({super.key})
    : super(
        create: (reg) => SettingsLogic(),
        builder: (context, logic) => _build(context, logic),
      );

  static Widget _build(BuildContext context, SettingsLogic logic) {
    return logic.isDarkMode.watch((context, isDark) {
      return logic.refreshInterval.watch((context, interval) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Persistent Settings'),
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
                  Colors.purple.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
              children: [
                _SettingsSection(
                  title: 'APPEARANCE',
                  children: [
                    _SettingsTile(
                      title: 'Dark Mode',
                      subtitle: 'Enable sleek dark aesthetics',
                      trailing: Switch(
                        value: isDark,
                        activeTrackColor: NanoHubTheme.accentColor.withValues(
                          alpha: 0.5,
                        ),
                        activeThumbColor: NanoHubTheme.accentColor,
                        onChanged: (_) => logic.toggleTheme(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SettingsSection(
                  title: 'PERFORMANCE',
                  children: [
                    _SettingsTile(
                      title: 'Refresh Interval',
                      subtitle: 'Current: ${interval.toStringAsFixed(1)}s',
                      trailing: SizedBox(
                        width: 150,
                        child: Slider(
                          value: interval,
                          min: 0.1,
                          max: 5.0,
                          activeColor: NanoHubTheme.primaryColor,
                          onChanged: logic.setRefreshInterval,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                const Text(
                  'All settings in this view are automatically saved to SharedPreferences via PersistAtom. Try restarting the app!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      });
    });
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.white54,
            ),
          ),
        ),
        Container(
          decoration: NanoHubTheme.glassDecoration(opacity: 0.03),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ),
      trailing: trailing,
    );
  }
}

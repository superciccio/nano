import 'package:flutter/material.dart';
import 'package:nano/nano.dart';
import 'package:nano_hub/core/theme.dart';
import 'package:nano_hub/features/streams/sensor_logic.dart';

class SensorStreamView extends NanoView<SensorLogic, void> {
  SensorStreamView({super.key})
    : super(
        create: (reg) => SensorLogic(),
        builder: (context, logic) => _build(context, logic),
      );

  static Widget _build(BuildContext context, SensorLogic logic) {
    return logic.currentReading.when(
      loading: (context) => const Center(child: CircularProgressIndicator()),
      error: (context, error) => Center(child: Text('Error: $error')),
      data: (context, reading) {
        final statsState = logic.statsWorker.value;
        // Graceful loading: use the last data if we're loading
        final stats = statsState.dataOrNull;
        final isLoading = statsState.isLoading;

        return _SensorContent(
          reading: reading,
          stats: stats,
          isProcessing: isLoading,
        );
      },
    );
  }
}

class _SensorContent extends StatelessWidget {
  final double reading;
  final SensorStats? stats;
  final bool isProcessing;

  const _SensorContent({
    required this.reading,
    this.stats,
    required this.isProcessing,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parallel Analytics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              NanoHubTheme.backgroundColor,
              NanoHubTheme.primaryColor.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SensorCard(
              title: 'Live Temperature',
              value: "${reading.toStringAsFixed(2)} °C",
              subtitle: 'Simulated sensor hardware (1Hz)',
              icon: Icons.thermostat,
            ),
            const SizedBox(height: 24),
            _AnalyticsCard(stats: stats, isProcessing: isProcessing),
            const SizedBox(height: 40),
            const Text(
              'WorkerAtom offloads computation to a background isolate.\nStatistics are calculated from a sliding history window.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final SensorStats? stats;
  final bool isProcessing;

  const _AnalyticsCard({this.stats, required this.isProcessing});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isProcessing ? 0.6 : 1.0,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: NanoHubTheme.glassDecoration(opacity: 0.05).copyWith(
          border: Border.all(
            color: NanoHubTheme.accentColor.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: NanoHubTheme.accentColor),
                const SizedBox(width: 12),
                const Text(
                  'Background Analytics',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: Colors.white70,
                  ),
                ),
                const Spacer(),
                if (isProcessing)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        NanoHubTheme.accentColor,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            if (stats == null)
              const Text(
                'Buffering history...',
                style: TextStyle(color: Colors.white38),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      label: 'MEAN',
                      value: stats!.mean.toStringAsFixed(1),
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      label: 'MAX',
                      value: stats!.max.toStringAsFixed(1),
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      label: 'MIN',
                      value: stats!.min.toStringAsFixed(1),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Text(
              'Sample size: ${stats?.count ?? 0} / 20',
              style: const TextStyle(color: Colors.white24, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: NanoHubTheme.accentColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _SensorCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: NanoHubTheme.glassDecoration(opacity: 0.05).copyWith(
        border: Border.all(
          color: NanoHubTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: NanoHubTheme.primaryColor),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

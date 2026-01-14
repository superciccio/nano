import 'dart:async';
import 'package:flutter/material.dart';
import 'package:devtools_extensions/devtools_extensions.dart';

class _HistoryEventDetails {
  final String label;
  final String oldValue;
  final String newValue;
  final String timestamp;

  _HistoryEventDetails({
    required this.label,
    required this.oldValue,
    required this.newValue,
    required this.timestamp,
  });

  factory _HistoryEventDetails.fromJson(Map<String, dynamic> json) {
    return _HistoryEventDetails(
      label: json['label']?.toString() ?? 'Unknown',
      oldValue: json['oldValue']?.toString() ?? '',
      newValue: json['newValue']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
    );
  }
}

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  HistoryViewState createState() => HistoryViewState();
}

class HistoryViewState extends State<HistoryView> {
  List<_HistoryEventDetails> _history = [];
  bool _isLoading = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshHistory();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _refreshHistory();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshHistory() async {
    if (_isLoading) return;

    final app = serviceManager.connectedApp;
    if (app == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await serviceManager.callServiceExtensionOnMainIsolate(
        'ext.nano.getHistory',
      );
      final json = response.json!;
      if (json['history'] != null) {
        final List<dynamic> historyList = json['history'];
        setState(() {
          _history = historyList
              .map((event) => _HistoryEventDetails.fromJson(event))
              .toList()
              .reversed
              .toList(); // Show newest first
        });
      }
    } catch (e) {
      //
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_history.isEmpty) {
      return const Center(
        child: Text(
          'No history yet. Interact with your app to see state changes.',
        ),
      );
    }

    return ListView.builder(
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final event = _history[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            title: Text(
              event.label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${event.oldValue} -> ${event.newValue}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  TimeOfDay.fromDateTime(
                    DateTime.parse(event.timestamp),
                  ).format(context),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.history),
                  tooltip: 'Revert to this state',
                  onPressed: () {
                    serviceManager.callServiceExtensionOnMainIsolate(
                      'ext.nano.revertToState',
                      args: {'label': event.label, 'value': event.oldValue},
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'dart:async';
import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const NanoDevToolsExtension());
}

class NanoDevToolsExtension extends StatelessWidget {
  const NanoDevToolsExtension({super.key});

  @override
  Widget build(BuildContext context) {
    return const DevToolsExtension(child: NanoExtensionBody());
  }
}

class NanoExtensionBody extends StatefulWidget {
  const NanoExtensionBody({super.key});

  @override
  State<NanoExtensionBody> createState() => _NanoExtensionBodyState();
}

class _NanoExtensionBodyState extends State<NanoExtensionBody> {
  List<dynamic> _atoms = [];
  bool _isLoading = false;
  String _lastUpdate = 'Never';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshAtoms();
    // Auto-refresh every 2 seconds if connected
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _refreshAtoms(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshAtoms() async {
    if (_isLoading) return;

    // Simple check for connection
    final app = serviceManager.connectedApp;
    if (app == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await serviceManager.callServiceExtensionOnMainIsolate(
        'ext.nano.getAtoms',
      );

      if (response.json != null && response.json!['atoms'] != null) {
        setState(() {
          _atoms = response.json!['atoms'];
          _lastUpdate =
              response.json!['timestamp'] ?? DateTime.now().toIso8601String();
        });
      }
    } catch (e) {
      // Silently fail on background refresh
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = serviceManager.connectedApp;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nano Atoms'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                'Last update: $_lastUpdate',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshAtoms),
        ],
      ),
      body: app == null
          ? const Center(
              child: Text(
                'No app connected. Please run your app and connect DevTools.',
              ),
            )
          : _isLoading && _atoms.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _atoms.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'No Atoms found.\n\nMake sure your app is running in debug mode and a Scope is initialized.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              itemCount: _atoms.length,
              itemBuilder: (context, index) {
                final atom = _atoms[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    title: Text(
                      atom['label'] ?? 'Unknown Atom',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Type: ${atom['type']}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          atom['value'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.blueGrey,
                          ),
                        ),
                        if (atom['state'] != null)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStateColor(
                                atom['state'],
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _getStateColor(atom['state']),
                              ),
                            ),
                            child: Text(
                              atom['state'].toUpperCase(),
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: _getStateColor(atom['state']),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _getStateColor(String state) {
    switch (state) {
      case 'loading':
        return Colors.blue;
      case 'error':
        return Colors.red;
      case 'data':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

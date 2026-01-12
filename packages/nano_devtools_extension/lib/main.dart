import 'dart:async';
import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'history_view.dart';

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

class _NanoExtensionBodyState extends State<NanoExtensionBody>
    with TickerProviderStateMixin {
  List<_AtomDetails> _atoms = [];
  bool _isLoading = false;
  Timer? _refreshTimer;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshAtoms();
    // Auto-refresh every 2 seconds if connected
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _refreshAtoms(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        final List<dynamic> atomList = response.json!['atoms'];
        setState(() {
          _atoms = atomList
              .map((atom) => _AtomDetails.fromJson(atom))
              .toList();
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
        title: const Text('Nano'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshAtoms),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Atoms'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: app == null
          ? const Center(
              child: Text(
                'No app connected. Please run your app and connect DevTools.',
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAtomsView(),
                const HistoryView(),
              ],
            ),
    );
  }

  Widget _buildAtomsView() {
    return _isLoading && _atoms.isEmpty
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
            : SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Label')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Value')),
                    DataColumn(label: Text('State')),
                    DataColumn(label: Text('Meta')),
                    DataColumn(label: Text('Last Update')),
                  ],
                  rows: _atoms.map((atom) {
                    return DataRow(
                      cells: [
                        DataCell(Text(atom.label)),
                        DataCell(Text(atom.type)),
                        DataCell(Text(atom.value)),
                        DataCell(
                          atom.state != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _getStateColor(atom.state!).withAlpha(26),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: _getStateColor(atom.state!),
                                    ),
                                  ),
                                  child: Text(
                                    atom.state!.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: _getStateColor(atom.state!),
                                    ),
                                  ),
                                )
                              : const Text(''),
                        ),
                        DataCell(
                          atom.meta.isEmpty
                              ? const Text('')
                              : Tooltip(
                                  message: atom.meta.toString(),
                                  child: Text(
                                    atom.meta.keys.join(', '),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                        ),
                        DataCell(Text(atom.lastUpdate)),
                      ],
                    );
                  }).toList(),
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

class _AtomDetails {
  final String label;
  final String type;
  final String value;
  final String? state;
  final Map<String, String> meta;
  final String lastUpdate;

  _AtomDetails({
    required this.label,
    required this.type,
    required this.value,
    this.state,
    required this.meta,
    required this.lastUpdate,
  });

  factory _AtomDetails.fromJson(Map<String, dynamic> json) {
    return _AtomDetails(
      label: json['label'] ?? 'Unknown Atom',
      type: json['type'],
      value: json['value'] ?? '',
      state: json['state'],
      meta: Map<String, String>.from(json['meta'] ?? {}),
      lastUpdate: json['timestamp'] ?? DateTime.now().toIso8601String(),
    );
  }
}

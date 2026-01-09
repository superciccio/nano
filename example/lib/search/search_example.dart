import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nano/nano.dart';

// Simulated API Service
class SearchService {
  Future<List<String>> search(String query) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (query.isEmpty) return [];
    if (query == 'error') throw Exception('Simulated API Error');

    final allResults = [
      'Apple', 'Banana', 'Cherry', 'Date', 'Elderberry', 'Fig', 'Grape',
      'Honeydew', 'Kiwi', 'Lemon', 'Mango', 'Nectarine', 'Orange', 'Papaya',
      'Quince', 'Raspberry', 'Strawberry', 'Tangerine', 'Ugli Fruit', 'Vanilla',
      'Watermelon', 'Xylophone', 'Yellow', 'Zucchini'
    ];

    return allResults
        .where((s) => s.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}

// Logic
class SearchLogic extends NanoLogic<dynamic> {
  final SearchService _service;
  SearchLogic(this._service);

  final query = DebouncedAtom<String>('',
      duration: const Duration(milliseconds: 500), label: 'query');

  // AsyncAtom manages loading, data, and error states automatically
  final results = AsyncAtom<List<String>>(label: 'results');

  @override
  void onInit(dynamic params) {
    // Listen to query changes to trigger search
    query.addListener(() {
      final q = query.value;
      if (q.isEmpty) {
        results.set(const AsyncIdle());
      } else {
        results.track(_service.search(q));
      }
    });
  }
}

// Page
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return NanoView<SearchLogic, dynamic>(
      create: (r) => r.get(),
      builder: (context, logic) {
        return Scaffold(
          appBar: AppBar(title: const Text('Async Search')),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search Fruits (try "apple", "error")',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (val) => logic.query(val),
                ),
              ),
              Expanded(
                child: logic.results.when(
                  idle: (context) =>
                      const Center(child: Text('Type to search...')),
                  loading: (context) =>
                      const Center(child: CircularProgressIndicator()),
                  error: (context, e) => Center(
                    child: Text(
                      'Error: $e',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  data: (context, items) => items.isEmpty
                      ? const Center(child: Text('No results found.'))
                      : ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(items[index]),
                              leading: const Icon(Icons.fastfood),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

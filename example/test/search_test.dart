import 'package:flutter_test/flutter_test.dart';
import 'package:nano/nano.dart';
import 'package:nano_example/search/search_example.dart';

// Manual Mock
class MockSearchService implements SearchService {
  final Map<String, List<String>> _mockResults = {
    'apple': ['Apple', 'Pineapple'],
    'ban': ['Banana'],
  };

  @override
  Future<List<String>> search(String query) async {
    // Simulate delay
    await Future.delayed(const Duration(milliseconds: 10));

    if (query == 'error') throw Exception('Mock Error');

    return _mockResults[query] ?? [];
  }
}

void main() {
  group('SearchLogic', () {
    late SearchLogic logic;
    late MockSearchService mockService;

    setUp(() {
      Nano.init();
      mockService = MockSearchService();
      logic = SearchLogic(mockService);
      logic.onInit(null); // Explicitly call onInit as View does
    });

    tearDown(() {
      logic.dispose();
    });

    test('initial state is idle', () {
      expect(logic.results.value, isA<AsyncIdle>());
      expect(logic.query.value, isEmpty);
    });

    test('search success updates results', () async {
      logic.query('apple');
      // Should still be idle because of debounce
      expect(logic.results.value, isA<AsyncIdle>());
      // Wait for debounce (500ms) + mock service delay (10ms)
      await Future.delayed(const Duration(milliseconds: 550));
      // Now should be loading, then data
      expect(logic.results.value, isA<AsyncData<List<String>>>());
      final data = (logic.results.value as AsyncData<List<String>>).data;
      expect(data, ['Apple', 'Pineapple']);
    });

    test('search error updates results', () async {
      logic.query('error');
      // Wait for debounce + mock service
      await Future.delayed(const Duration(milliseconds: 550));
      expect(logic.results.value, isA<AsyncError>());
      final errorState = logic.results.value as AsyncError;
      expect(errorState.error.toString(), contains('Mock Error'));
    });

    test('empty query sets state to idle after debounce', () async {
      // First, perform a search
      logic.query('apple');
      await Future.delayed(const Duration(milliseconds: 550));
      expect(logic.results.value, isA<AsyncData>());

      // Now, clear the query
      logic.query('');
      // It should not immediately change to idle
      expect(logic.results.value, isA<AsyncData>());

      // Wait for debounce
      await Future.delayed(const Duration(milliseconds: 550));
      expect(logic.results.value, isA<AsyncIdle>());
    });
  });
}

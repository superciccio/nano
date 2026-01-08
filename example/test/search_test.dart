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

    test('empty query sets state to idle', () async {
      logic.query('some query');
      // Wait for debounce (500ms) - we can't easily skip it without modifying logic,
      // but we can just test the immediate effect of empty string if that path is synchronous
      // logic.query('') is synchronous in setting Idle if query is empty.

      logic.query('');
      expect(logic.results.value, isA<AsyncIdle>());
    });

    test('search success updates results', () async {
      // We need to wait for debounce (500ms) + mock delay (10ms)
      // Since we can't use fakeAsync easily with Timer in logic without injecting a scheduler,
      // we will just wait. 500ms is acceptable for a test suite.

      logic.query('apple');

      expect(logic.results.value, isA<AsyncIdle>()); // Still idle due to debounce

      // Wait for debounce to trigger
      await Future.delayed(const Duration(milliseconds: 550));

      // Should be loading or done (since mock is fast)
      // With 10ms mock delay, it should be done.

      expect(logic.results.value, isA<AsyncData<List<String>>>());
      final data = (logic.results.value as AsyncData<List<String>>).data;
      expect(data, ['Apple', 'Pineapple']);
    });

    test('search error updates results', () async {
      logic.query('error');

      await Future.delayed(const Duration(milliseconds: 600));

      expect(logic.results.value, isA<AsyncError>());
      final errorState = logic.results.value as AsyncError;
      expect(errorState.error.toString(), contains('Mock Error'));
    });
  });
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:rick_and_morty/main.dart';
import 'package:rick_and_morty/rm_logic.dart';
import 'package:nano/nano.dart';

// Mock Service
class MockRMService implements RickAndMortyService {
  @override
  Future<List<Character>> fetchCharacters(int page) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return [
      Character(
        id: 1,
        name: 'Rick Sanchez',
        status: 'Alive',
        species: 'Human',
        image: 'https://example.com/rick.png',
        episodeUrls: ['https://rickandmortyapi.com/api/episode/1'],
      ),
    ];
  }

  @override
  Future<List<Episode>> fetchEpisodes(List<String> episodeUrls) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return [
      Episode(name: 'Pilot', episodeCode: 'S01E01', airDate: 'Dec 2, 2013'),
    ];
  }
}

void main() {
  testWidgets('R&M: Select character and load episodes', (WidgetTester tester) async {
    await HttpOverrides.runZoned(() async {
      // Inject Mock via Scope
      await tester.pumpWidget(
        Scope(
          modules: [
            NanoFactory<RickAndMortyService>((_) => MockRMService()),
          ],
          child: const RickAndMortyApp(),
        ),
      );

      // Initial load
      await tester.pump(); // Start fetchCharacters
      await tester.pump(const Duration(milliseconds: 100)); // Finish fetch

      expect(find.text('Rick Sanchez'), findsOneWidget);

      // Tap character
      await tester.tap(find.text('Rick Sanchez'));
      await tester.pump(); // Select and start fetchEpisodes

      // Check loading in detail view
      expect(find.text('EPISODES APPEARANCES'), findsOneWidget);

      // Wait for episodes
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Pilot'), findsOneWidget);
      expect(find.text('S01E01'), findsOneWidget);
    }, createHttpClient: (_) => _TestHttpClient());
  });
}

// -----------------------------------------------------------------------------
// Test Helpers for Network Images
// -----------------------------------------------------------------------------

final _transparentImage = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
];

class _TestHttpClient implements HttpClient {
  @override
  bool autoUncompress = false;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}

  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) {}

  @override
  set authenticate(Future<bool> Function(Uri url, String scheme, String? realm)? f) {}

  @override
  set authenticateProxy(Future<bool> Function(String host, int port, String scheme, String? realm)? f) {}

  @override
  set badCertificateCallback(bool Function(X509Certificate cert, String host, int port)? callback) {}

  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) => throw UnimplementedError();

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => throw UnimplementedError();

  @override
  Future<HttpClientRequest> get(String host, int port, String path) => throw UnimplementedError();

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _TestHttpClientRequest();
  }

  @override
  Future<HttpClientRequest> head(String host, int port, String path) => throw UnimplementedError();

  @override
  Future<HttpClientRequest> headUrl(Uri url) => throw UnimplementedError();

  @override
  Future<HttpClientRequest> open(String method, String host, int port, String path) => throw UnimplementedError();

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) => throw UnimplementedError();

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) => throw UnimplementedError();

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => throw UnimplementedError();

  @override
  Future<HttpClientRequest> post(String host, int port, String path) => throw UnimplementedError();

  @override
  Future<HttpClientRequest> postUrl(Uri url) => throw UnimplementedError();

  @override
  Future<HttpClientRequest> put(String host, int port, String path) => throw UnimplementedError();

  @override
  Future<HttpClientRequest> putUrl(Uri url) => throw UnimplementedError();

  @override
  set findProxy(String Function(Uri url)? f) {}
  
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Fallback
    return null;
  }
}

class _TestHttpClientRequest implements HttpClientRequest {
  @override
  Encoding get encoding => throw UnimplementedError();
  @override
  set encoding(Encoding value) => throw UnimplementedError();
  
  @override
  HttpHeaders get headers => _TestHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return _TestHttpClientResponse();
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _TestHttpHeaders implements HttpHeaders {
  @override
  bool chunkedTransferEncoding = false;
  @override
  int contentLength = -1;
  @override
  ContentType? contentType;
  @override
  DateTime? date;
  @override
  DateTime? expires;
  @override
  String? host;
  @override
  DateTime? ifModifiedSince;
  @override
  bool persistentConnection = true;
  @override
  int? port;

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _TestHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;
  
  @override
  int get contentLength => _transparentImage.length;
  
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;
  
  @override
  HttpHeaders get headers => _TestHttpHeaders();

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.fromIterable([_transparentImage]).listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
  
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

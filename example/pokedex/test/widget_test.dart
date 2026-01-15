import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex/main.dart';
import 'package:pokedex/pokedex_logic.dart';
import 'package:nano/nano.dart';

// Mock Service
class MockPokedexService implements PokedexService {
  @override
  Future<Pokemon> fetchPokemon(String name) async {
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate net

    if (name == 'pikachu') {
      return Pokemon(
        id: 25,
        name: 'pikachu',
        height: 4,
        weight: 60,
        spriteUrl: 'https://example.com/pikachu.png',
        types: ['electric'],
        flavorText: 'Pika Pika!',
        isLegendary: false,
      );
    } else {
      throw 'Pokemon "$name" not found!';
    }
  }
}

void main() {
  testWidgets('Pokedex UI starts in idle state', (WidgetTester tester) async {
    await tester.pumpWidget(
      Scope(
        modules: [
          NanoFactory<PokedexService>((_) => MockPokedexService()),
        ],
        child: const PokedexApp(),
      ),
    );

    expect(find.text('NANO POKEDEX'), findsOneWidget);
    expect(find.text('WAITING FOR INPUT'), findsOneWidget);
  });

  testWidgets('Search updates state and UI', (WidgetTester tester) async {
    await HttpOverrides.runZoned(() async {
      await tester.pumpWidget(
        Scope(
          modules: [
            NanoFactory<PokedexService>((_) => MockPokedexService()),
          ],
          child: const PokedexApp(),
        ),
      );

      // Initial State
      expect(find.text('WAITING FOR INPUT'), findsOneWidget);

      // Enter text and submit
      await tester.enterText(find.byType(TextField), 'pikachu');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      // Check loading
      await tester.pump(); // Start future (AsyncAtom transitions to loading immediately)
      expect(find.text('ANALYZING...'), findsOneWidget);

      // Finish future
      await tester.pump(const Duration(milliseconds: 150));

      // Check Success
      // New UI splits ID and Name
      expect(find.text('No. 025'), findsOneWidget);
      expect(find.text('PIKACHU'), findsOneWidget);
      
      // Type is uppercase
      expect(find.text('ELECTRIC'), findsOneWidget);
      
      // Flavor text
      expect(find.text('Pika Pika!'), findsOneWidget);
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
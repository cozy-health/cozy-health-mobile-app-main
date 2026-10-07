import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

/// Exercises the real API client and cache without network or platform storage.
class RepositoryFixture<T> {
  RepositoryFixture(this.boxName, this.adapter);

  final String boxName;
  final TypeAdapter<T> adapter;
  dynamic body;
  final List<Uri> requests = [];
  late Directory _directory;
  HttpOverrides? _previousOverrides;
  late Box<T> box;

  Future<void> open() async {
    FlutterSecureStorage.setMockInitialValues({});
    _directory = await Directory.systemTemp.createTemp('cozy_repository_test_');
    Hive.init(_directory.path);
    Hive.registerAdapter(adapter);
    box = await Hive.openBox<T>(boxName);
    _previousOverrides = HttpOverrides.current;
    HttpOverrides.global = _ResponseOverrides(() => body, requests);
  }

  Future<void> reset() async {
    body = const [];
    requests.clear();
    await box.clear();
  }

  Future<void> close() async {
    HttpOverrides.global = _previousOverrides;
    await Hive.close();
    Hive.resetAdapters();
    await _directory.delete(recursive: true);
  }
}

class _ResponseOverrides extends HttpOverrides {
  _ResponseOverrides(this.body, this.requests);
  final dynamic Function() body;
  final List<Uri> requests;

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _ResponseClient(body, requests);
}

class _ResponseClient implements HttpClient {
  _ResponseClient(this.body, this.requests);
  final dynamic Function() body;
  final List<Uri> requests;

  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 3);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    requests.add(url);
    return _ResponseRequest(body());
  }

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ResponseRequest implements HttpClientRequest {
  _ResponseRequest(this.body);
  final dynamic body;

  @override
  final HttpHeaders headers = _ResponseHeaders();
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  bool persistentConnection = true;

  @override
  Future<HttpClientResponse> close() async => _JsonResponse(body);

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ResponseHeaders implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void forEach(void Function(String name, List<String> values) action) {
    action(HttpHeaders.contentTypeHeader, ['application/json']);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _JsonResponse extends Stream<List<int>> implements HttpClientResponse {
  _JsonResponse(dynamic body) : _bytes = utf8.encode(jsonEncode(body));
  final List<int> _bytes;

  @override
  final HttpHeaders headers = _ResponseHeaders();
  @override
  int get statusCode => HttpStatus.ok;
  @override
  String get reasonPhrase => 'OK';
  @override
  bool get isRedirect => false;
  @override
  List<RedirectInfo> get redirects => const [];
  @override
  int get contentLength => _bytes.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(_bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

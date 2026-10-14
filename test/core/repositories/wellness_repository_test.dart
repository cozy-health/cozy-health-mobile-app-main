import 'dart:convert';
import 'dart:typed_data';
import 'package:cozy_health/core/api/api_client.dart';
import 'package:cozy_health/core/data/demo_mode.dart';
import 'package:cozy_health/core/repositories/wellness_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CatalogAdapter implements HttpClientAdapter {
  int status = 200;
  dynamic body = {
    'data': {
      'moods': [
        {'slug': 'calm', 'name': 'Calm'},
      ],
      'expressions': [],
      'triggers': [],
      'coping': [],
      'packages': [],
    },
  };
  final List<RequestOptions> requests = [];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CatalogAdapter adapter;
  late HttpClientAdapter previous;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    DemoMode.instance.enabled = false;
    previous = ApiClient.instance.transportForTesting;
    adapter = CatalogAdapter();
    ApiClient.instance.transportForTesting = adapter;
  });
  tearDown(() {
    ApiClient.instance.transportForTesting = previous;
  });
  test(
    'managed catalog is cached and remains available after an unsuccessful refresh',
    () async {
      final repository = WellnessRepository();
      final fresh = await repository.catalog();
      expect(fresh!['moods'][0]['slug'], 'calm');
      adapter.status = 400;
      final cached = await repository.catalog();
      expect(cached, fresh);
    },
  );
  test('malformed cache never prevents reading a fresh catalog', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('cozy.wellness.catalog.v1', 'invalid');
    expect(await WellnessRepository().catalog(), isNotNull);
  });
  test(
    'demo mode keeps the existing local choices without sending requests',
    () async {
      DemoMode.instance.enabled = true;
      expect(await WellnessRepository().catalog(), isNull);
      expect(adapter.requests, isEmpty);
      DemoMode.instance.enabled = false;
    },
  );
  test('challenge actions use the selected challenge and day', () async {
    final repository = WellnessRepository();
    await repository.enroll(7);
    await repository.complete(7, 1);
    expect(adapter.requests.first.path, '/wellness/challenges/7/enroll');
    expect(adapter.requests.last.path, '/wellness/challenges/7/complete');
    expect(adapter.requests.last.data, {'day': 1});
  });
}

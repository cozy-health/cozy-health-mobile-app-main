import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:cozy_health/core/api/api_transport_io.dart';
import 'package:cozy_health/core/api/api_destination_policy.dart';
import 'package:cozy_health/core/constants/api_constants.dart';

Future<void> main() async {
  final uri = Uri.parse(ApiConstants.baseUrl).replace(path: '/up');
  final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 15)))
    ..httpClientAdapter = createApiTransport(
      ApiDestinationPolicy(host: uri.host),
    );
  try {
    final response = await dio.getUri(uri);
    debugPrint('Native debug transport /up: HTTP ${response.statusCode}');
  } finally {
    dio.close(force: true);
  }
}

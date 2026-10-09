import 'package:dio/dio.dart';
import '../lib/core/api/api_transport_io.dart';
import '../lib/core/api/leaf_pin_policy.dart';

Future<void> main() async {
  final uri = Uri.parse('https://cozy-health-api-production.up.railway.app/up');
  final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 15)))
    ..httpClientAdapter = createApiTransport(
      LeafPinPolicy(host: uri.host, current: '', next: ''),
      requirePins: false,
    );
  try {
    final response = await dio.getUri(uri);
    print('Native debug transport /up: HTTP ${response.statusCode}');
  } finally {
    dio.close(force: true);
  }
}

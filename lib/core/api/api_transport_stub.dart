import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'api_destination_policy.dart';

HttpClientAdapter createApiTransport(ApiDestinationPolicy policy) =>
    _UnsupportedTransport();

// The mobile health client uses the native API transport.
class _UnsupportedTransport implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async => throw DioException.badCertificate(
    requestOptions: options,
    error: 'The health app API requires a native client.',
  );
  @override
  void close({bool force = false}) {}
}

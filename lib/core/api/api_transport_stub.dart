import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'leaf_pin_policy.dart';

HttpClientAdapter createApiTransport(LeafPinPolicy policy) =>
    _UnsupportedTransport();

// Browsers cannot expose the peer leaf certificate to Dio. Do not claim pinning.
class _UnsupportedTransport implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async => throw DioException.badCertificate(
    requestOptions: options,
    error: 'Pinned health API requires a native client.',
  );
  @override
  void close({bool force = false}) {}
}

import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'api_destination_policy.dart';

HttpClientAdapter createApiTransport(ApiDestinationPolicy policy) =>
    VerifiedApiAdapter(policy);

class VerifiedApiAdapter implements HttpClientAdapter {
  VerifiedApiAdapter(this.policy, {SecurityContext? context}) {
    _inner = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient(context: context);
        client.findProxy = (_) => 'DIRECT';
        client.connectionFactory = (uri, proxyHost, proxyPort) async {
          if (!policy.permits(uri) || proxyHost != null || proxyPort != null) {
            throw const HandshakeException('API destination is unavailable.');
          }
          // Verify the chain, hostname and expiry before sending HTTP headers.
          final task = await SecureSocket.startConnect(
            uri.host,
            uri.port,
            context: context,
          );
          return ConnectionTask.fromSocket(task.socket, task.cancel);
        };
        return client;
      },
    );
  }
  final ApiDestinationPolicy policy;
  late final IOHttpClientAdapter _inner;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) {
    if (!policy.permits(options.uri)) {
      throw DioException.badCertificate(
        requestOptions: options,
        error: 'API destination is invalid.',
      );
    }
    // No redirects, including same-host redirects, can bypass the destination gate.
    return _inner.fetch(
      options.copyWith(followRedirects: false),
      stream,
      cancelFuture,
    );
  }

  @override
  void close({bool force = false}) => _inner.close(force: force);
}

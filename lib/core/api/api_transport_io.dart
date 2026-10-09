import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'leaf_pin_policy.dart';

HttpClientAdapter createApiTransport(
  LeafPinPolicy policy, {
  bool requirePins = true,
}) => PinnedApiAdapter(policy, requirePins: requirePins);

class PinnedApiAdapter implements HttpClientAdapter {
  PinnedApiAdapter(
    this.policy, {
    SecurityContext? context,
    this.requirePins = true,
  }) {
    _inner = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient(context: context);
        client.findProxy = (_) => 'DIRECT';
        client.connectionFactory = (uri, proxyHost, proxyPort) async {
          if ((requirePins && !policy.ready) ||
              !policy.permits(uri) ||
              proxyHost != null ||
              proxyPort != null) {
            throw const HandshakeException(
              'Pinned API connection is unavailable.',
            );
          }
          // SecureSocket uses normal chain/hostname/expiry verification. The leaf
          // pin is checked before HttpClient receives a socket or sends headers.
          final task = await SecureSocket.startConnect(
            uri.host,
            uri.port,
            context: context,
          );
          final verified = task.socket.then<Socket>((socket) {
            if (requirePins &&
                !policy.accepts(
                  socket.peerCertificate?.der,
                  uri.host,
                  uri.port,
                )) {
              socket.destroy();
              throw const HandshakeException('API certificate pin mismatch.');
            }
            return socket;
          });
          return ConnectionTask.fromSocket(verified, task.cancel);
        };
        return client;
      },
      // Defense in depth; this callback alone runs after sending the request.
      validateCertificate: (cert, host, port) =>
          !requirePins || policy.accepts(cert?.der, host, port),
    );
  }
  final LeafPinPolicy policy;
  final bool requirePins;
  late final IOHttpClientAdapter _inner;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) {
    if ((requirePins && !policy.ready) || !policy.permits(options.uri)) {
      throw DioException.badCertificate(
        requestOptions: options,
        error: 'API pin configuration or destination is invalid.',
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

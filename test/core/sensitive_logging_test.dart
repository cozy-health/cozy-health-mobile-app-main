import 'package:cozy_health/core/api/api_interceptors.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'API logging never includes bodies, headers, query strings or errors',
    () async {
      final messages = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) messages.add(message);
      };
      try {
        const secret = 'PRIVATE_EMAIL_TOKEN_JOURNAL';
        final options = RequestOptions(
          path: '/sync/batch/$secret',
          method: 'POST',
          data: {'token': secret, 'journal': secret},
          headers: {'Authorization': secret},
          queryParameters: {'email': secret},
        );
        final logging = LoggingInterceptor();
        logging.onRequest(options, RequestInterceptorHandler());
        logging.onResponse(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {'content': secret},
          ),
          ResponseInterceptorHandler(),
        );
        final handler = ErrorInterceptorHandler();
        final completed = handler.future.then<void>(
          (_) {},
          onError: (Object _) {},
        );
        logging.onError(
          DioException(
            requestOptions: options,
            message: secret,
            error: StateError(secret),
          ),
          handler,
        );
        await completed;
        expect(messages.join(), contains('<redacted>'));
        expect(messages.join(), isNot(contains(secret)));
        expect(messages.join(), isNot(contains('/sync')));
      } finally {
        debugPrint = original;
      }
    },
  );
}

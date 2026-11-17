import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/core/api/api_exceptions.dart';
import 'package:cozy_health/core/api/api_interceptors.dart';
import 'package:cozy_health/core/services/age_action_feedback.dart';

void main() {
  test(
    'guardian actions preserve validation fields and resend timing through the interceptor',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://fixture.invalid'));
      dio.interceptors.add(ErrorInterceptor());
      addTearDown(() => dio.close(force: true));
      dio.httpClientAdapter = _Failure(
        422,
        '{"errors":{"guardian_email":["Enter a valid email address."]}}',
      );
      try {
        await dio.post('/me/guardian');
        fail('Expected validation failure');
      } on DioException catch (error) {
        final feedback = AgeActionFeedback.from(error.error!);
        expect(
          feedback.fieldErrors['guardian_email'],
          'Enter a valid email address.',
        );
        expect(feedback.message, contains('highlighted'));
      }
      dio.httpClientAdapter = _Failure(
        429,
        '{"code":"guardian_rate_limited","retry_after":60}',
      );
      try {
        await dio.post('/me/guardian');
        fail('Expected rate limit');
      } on DioException catch (error) {
        expect(
          AgeActionFeedback.from(error.error!).message,
          contains('1 minute'),
        );
      }
    },
  );

  test(
    'guardian errors explain verification and availability without rendering debug text',
    () {
      expect(
        AgeActionFeedback.from(
          ApiAgeActionException(
            statusCode: 403,
            fieldErrors: {},
            code: 'guardian_email_unverified',
          ),
        ).message,
        contains('Verify my email'),
      );
      expect(
        AgeActionFeedback.from(
          ApiAgeActionException(
            statusCode: 503,
            fieldErrors: {},
            code: 'guardian_unavailable',
          ),
        ).message,
        contains('not available yet'),
      );
      expect(
        AgeActionFeedback.from(
          ApiAgeActionException(
            statusCode: 422,
            fieldErrors: {},
            code: 'guardian_email_matches',
          ),
        ).fieldErrors,
        contains('guardian_email'),
      );
      expect(
        AgeActionFeedback.from(
          ApiAgeActionException(
            statusCode: 409,
            fieldErrors: {},
            code: 'age_correction_required',
          ),
        ).message,
        contains('Wrong date of birth'),
      );
      expect(
        AgeActionFeedback.from(
          ApiUnknownException('SQL and private debug details'),
        ).message,
        isNot(contains('SQL')),
      );
      expect(
        AgeActionFeedback.from(ApiTimeoutException()).message,
        contains('Check access before retrying'),
      );
    },
  );

  test(
    'expired invitations and withdrawal reviews have honest status explanations',
    () {
      expect(
        guardianAuthorizationStatus({
          'status': 'pending',
          'expires_at': '2000-01-01T00:00:00Z',
        }),
        contains('expired'),
      );
      expect(
        guardianAuthorizationStatus({
          'status': 'withdrawal_confirmed',
          'session_expires_at': '2000-01-01T00:00:00Z',
        }),
        contains('has not been withdrawn'),
      );
      expect(
        guardianRequestStatus('confirmed'),
        contains('still needs to make a decision'),
      );
      expect(
        guardianRequestStatus('future_unknown_status'),
        isNot(contains('future_unknown_status')),
      );
    },
  );
}

class _Failure implements HttpClientAdapter {
  _Failure(this.status, this.body);
  final int status;
  final String body;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    body,
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
  @override
  void close({bool force = false}) {}
}

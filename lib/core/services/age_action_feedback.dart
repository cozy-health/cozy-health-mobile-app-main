import '../api/api_exceptions.dart';

class AgeActionFeedback {
  const AgeActionFeedback(this.message, {this.fieldErrors = const {}});
  final String message;
  final Map<String, String> fieldErrors;

  factory AgeActionFeedback.from(Object error) {
    if (error is ApiNetworkException || error is ApiTimeoutException) {
      return const AgeActionFeedback(
        'The connection was interrupted. Your details are still here. Check access before retrying to see whether this step was saved.',
      );
    }
    if (error is ApiSecureConnectionException) {
      return const AgeActionFeedback(
        'A secure connection could not be established. Try a trusted connection before retrying.',
      );
    }
    if (error is ApiAuthException) {
      return const AgeActionFeedback(
        'Your session has expired. Sign in again to continue.',
      );
    }
    final fields = <String, String>{};
    if (error is ApiValidationException) {
      for (final entry in error.fieldErrors.entries) {
        if (entry.value.isNotEmpty) fields[entry.key] = entry.value.first;
      }
    }
    if (error is ApiAgeActionException) {
      final retry = error.retryAfterSeconds;
      final minutes = retry == null ? null : (retry / 60).ceil();
      final message = switch (error.code) {
        'guardian_unavailable' =>
          'Guardian invitations are not available yet. Your details are still here. Contact the team if you need help.',
        'guardian_delivery_failed' =>
          'We could not send the invitation. Your details are still here; please wait before trying again.',
        'guardian_email_unverified' =>
          'Verify your own email using “Verify my email”, then send the invitation.',
        'guardian_email_matches' =>
          'Enter your parent or legal guardian’s own email address, different from yours.',
        'guardian_not_applicable' =>
          'Check your age details. Guardian invitations apply to accounts aged 13–17.',
        'age_case_open' =>
          'An age or guardian case needs the team’s review. Check your team requests below before sending another invitation.',
        'age_correction_required' =>
          'Your birthday is already recorded. Choose “Wrong date of birth” under team help to request a correction.',
        _ when error.statusCode == 429 =>
          minutes == null
              ? 'Too many attempts. Your details are still here; please wait before trying again.'
              : 'Please wait $minutes ${minutes == 1 ? 'minute' : 'minutes'} before trying again. Your details are still here.',
        _ when error.statusCode == 422 =>
          'Check the highlighted details, then try again.',
        _ when error.statusCode == 409 =>
          'This request has changed. Check access again and review its current status before retrying.',
        _ when error.statusCode == 403 =>
          'Check your age details and email verification, or ask the team for help below.',
        _ =>
          'The service is temporarily unavailable. Your details are still here. Check access before retrying.',
      };
      if (error.code == 'guardian_email_matches') {
        fields['guardian_email'] = message;
      }
      return AgeActionFeedback(message, fieldErrors: fields);
    }
    return AgeActionFeedback(
      fields.isEmpty
          ? 'This step was not confirmed. Your details are still here. Check access before retrying.'
          : 'Check the highlighted details, then try again.',
      fieldErrors: fields,
    );
  }
}

String guardianRequestStatus(Object? status) => switch (status) {
  'pending' =>
    'Invitation sent. Your guardian needs to open the email and review the request.',
  'confirmed' =>
    'Email confirmed. Your guardian still needs to make a decision. An expired review needs a new invitation.',
  'authorized' =>
    'Guardian authorization recorded. Your own consent and other access requirements still apply.',
  'withdrawal_confirmed' =>
    'Withdrawal email confirmed. Authorization stays in place until your guardian confirms withdrawal.',
  'declined' =>
    'Your guardian declined this request. Contact the team if you need help.',
  'disputed' =>
    'The recipient said they are not your guardian. The team needs to review the case.',
  'withdrawn' || 'cancelled' =>
    'Authorization withdrawn or request cancelled. Your private records have been preserved.',
  'delivery_failed' =>
    'The invitation could not be sent. Check the email address and try again after the waiting period.',
  'expired' =>
    'This invitation has expired. Send a new one when invitations are available.',
  'replaced' =>
    'A newer invitation replaced this request. Use the newest email.',
  'country_changed' =>
    'Your residence changed. Check access to see the current requirements.',
  'adulthood' =>
    'Guardian authorization has ended because you are now 18. Your own consent still applies.',
  'review_required' =>
    'A new guardian review is required after the team’s update.',
  _ => 'Check access again to see the current request status.',
};

String guardianAuthorizationStatus(Object? authorization) {
  if (authorization is! Map) return guardianRequestStatus(null);
  final status = authorization['status'];
  final expiration = DateTime.tryParse(
    '${authorization[status == 'pending' ? 'expires_at' : 'session_expires_at']}',
  );
  if (expiration != null &&
      expiration.isBefore(DateTime.now()) &&
      ['pending', 'confirmed', 'withdrawal_confirmed'].contains(status)) {
    return status == 'withdrawal_confirmed'
        ? 'The withdrawal review expired. Your guardian can request a fresh withdrawal link; authorization has not been withdrawn.'
        : guardianRequestStatus('expired');
  }
  return guardianRequestStatus(status);
}

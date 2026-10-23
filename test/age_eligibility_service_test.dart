import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/core/services/age_eligibility_service.dart';

void main() {
  test(
    'stale age flags and server denial cannot reactivate retired onboarding',
    () async {
      var calls = 0;
      final service = AgeEligibilityService(
        enforcement: () => true,
        fetch: () async {
          calls++;
          throw StateError('Retired endpoint');
        },
      );
      await service.refresh();
      service.restricted({'allowed': false, 'reason': 'guardian_required'});
      await service.requirePrivateAccess();
      expect(service.enabled, isFalse);
      expect(service.blocked, isFalse);
      expect(calls, 0);
      await expectLater(service.submit('/me/guardian', {}), throwsStateError);
      service.dispose();
    },
  );
}

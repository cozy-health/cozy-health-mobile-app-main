import 'package:cozy_health/core/services/telemetry_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reporting requires matching environments and release activation', () {
    for (final app in ['development', 'production', 'unknown']) {
      for (final reporting in ['', 'development', 'production', 'unknown']) {
        for (final internal in [false, true]) {
          for (final enabled in [false, true]) {
            final expected =
                app == reporting &&
                ((app == 'development' && internal) ||
                    (app == 'production' && !internal && enabled));
            expect(
              TelemetryPolicy.allows(
                appEnvironment: app,
                reportingEnvironment: reporting,
                internalBuild: internal,
                productionEnabled: enabled,
              ),
              expected,
              reason:
                  '$app / $reporting / internal=$internal / enabled=$enabled',
            );
          }
        }
      }
    }
  });
}

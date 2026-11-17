import '../constants/api_constants.dart';

/// Reporting follows the API environment and requires explicit release opt-in.
class TelemetryPolicy {
  static const environment = String.fromEnvironment(
    'TELEMETRY_ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get enabled => allows(
    appEnvironment: ApiConstants.environment,
    reportingEnvironment: const String.fromEnvironment('TELEMETRY_ENVIRONMENT'),
    internalBuild: const bool.fromEnvironment('INTERNAL_TEST_BUILD'),
    productionEnabled: const bool.fromEnvironment(
      'PRODUCTION_TELEMETRY_ENABLED',
    ),
  );

  static bool allows({
    required String appEnvironment,
    required String reportingEnvironment,
    required bool internalBuild,
    required bool productionEnabled,
  }) {
    if (appEnvironment != reportingEnvironment) return false;
    return switch (appEnvironment) {
      'development' => internalBuild,
      'production' => !internalBuild && productionEnabled,
      _ => false,
    };
  }
}

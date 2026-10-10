import 'package:flutter/foundation.dart';

/// Internal sideload artifacts use platform-verified TLS while production
/// artifacts also require the independently supplied certificate pins.
class NetworkBuildPolicy {
  const NetworkBuildPolicy({
    this.debug = kDebugMode,
    this.internalTesting = const bool.fromEnvironment('INTERNAL_TEST_BUILD'),
  });

  final bool debug;
  final bool internalTesting;
  bool get requirePins => !debug && !internalTesting;
}

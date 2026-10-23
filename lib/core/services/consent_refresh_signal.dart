import 'package:flutter/foundation.dart';

/// A current-session server denial invalidates any previously displayed consent.
final consentRefreshSignal = ValueNotifier<int>(0);

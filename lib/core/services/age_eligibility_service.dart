import 'package:flutter/foundation.dart';

class AgeEligibilityState {
  const AgeEligibilityState(this.data);
  final Map<String, dynamic> data;
  bool get allowed => true;
  bool get onlineRequired => false;
  String? get reason => null;
  String get band => 'unknown';
}

/// Compatibility only. Store ratings replace the custom age/guardian journey.
class AgeEligibilityService extends ChangeNotifier {
  AgeEligibilityService({this.fetch, this.token, this.enforcement});
  static final instance = AgeEligibilityService();
  final Future<Map<String, dynamic>> Function()? fetch;
  final Future<String?> Function()? token;
  final bool Function()? enforcement;
  AgeEligibilityState? current;
  bool get enabled => false;
  bool get blocked => false;
  void invalidate() {
    current = null;
    notifyListeners();
  }

  Future<void> refresh() async {}
  Future<void> requirePrivateAccess() async {}
  Future<void> submit(String path, Map<String, dynamic> data) async {
    throw StateError('The custom age and guardian process has been retired.');
  }

  Future<void> updateResidence(String country) async {
    throw StateError('The custom age and guardian process has been retired.');
  }

  Future<void> cancelGuardian() async {
    throw StateError('The custom age and guardian process has been retired.');
  }

  void restricted(Map<String, dynamic> state) {}
}

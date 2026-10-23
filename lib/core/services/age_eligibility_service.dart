import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../storage/token_storage.dart';
import 'feature_flags_service.dart';
import 'local_db_service.dart';
import 'network_status.dart';

class AgeEligibilityState {
  const AgeEligibilityState(this.data);
  final Map<String, dynamic> data;
  bool get allowed => data['allowed'] == true;
  bool get onlineRequired => data['online_required'] != false;
  String? get reason => data['reason'] as String?;
  String get band => data['age_band'] as String? ?? 'unknown';
}

class AgeEligibilityService extends ChangeNotifier {
  AgeEligibilityService({this.fetch, this.token, this.enforcement});
  static final instance = AgeEligibilityService();
  final Future<Map<String, dynamic>> Function()? fetch;
  final Future<String?> Function()? token;
  final bool Function()? enforcement;
  AgeEligibilityState? current;
  String? _session;
  Future<void>? _loading;
  int _epoch = 0;
  bool _denied = false;
  bool get enabled =>
      enforcement?.call() ??
      FeatureFlagsService.instance.configuration.ageEnforcement;
  bool get blocked =>
      enabled &&
      (current?.allowed != true ||
          current?.data['enforced'] != true ||
          (current!.onlineRequired && networkOffline.value != false));

  void invalidate() {
    _epoch++;
    current = null;
    _session = null;
    notifyListeners();
  }

  Future<void> refresh() =>
      _loading ??= _refresh().whenComplete(() => _loading = null);
  Future<void> _refresh() async {
    final epoch = _epoch;
    final session = await (token?.call() ?? TokenStorage().getToken());
    if (session != _session) {
      current = null;
      _session = session;
      notifyListeners();
    }
    if (session == null) {
      current = null;
      notifyListeners();
      return;
    }
    try {
      final Map<String, dynamic> data;
      if (fetch != null) {
        data = await fetch!();
      } else {
        final response = await ApiClient().get('/me/eligibility');
        data = Map<String, dynamic>.from(
          (response as Response).data['data'] as Map,
        );
      }
      if (await (token?.call() ?? TokenStorage().getToken()) != session ||
          epoch != _epoch) {
        return;
      }
      if (data['allowed'] is! bool || data['owner_id'] == null) {
        throw const FormatException('Invalid eligibility response');
      }
      current = AgeEligibilityState(data);
      _denied = !current!.allowed;
      if (fetch == null) {
        final local = LocalDbService();
        final settings = await local.settingsBox();
        if (settings.get('device_user_id')?.toString() ==
            data['owner_id'].toString()) {
          // Only adult offline eligibility is persisted. Minor authorization never is.
          await settings.put(
            'age_adult_offline',
            data['enforced'] == true &&
                current!.band == 'adult' &&
                current!.allowed,
          );
        }
      }
    } catch (_) {
      // A failed request cannot extend a minor's authorization window.
      if (await (token?.call() ?? TokenStorage().getToken()) != session ||
          epoch != _epoch) {
        return;
      }
      current = null;
      if (fetch == null && !_denied && networkOffline.value == true) {
        try {
          final settings = await LocalDbService().settingsBox();
          if (settings.get('age_adult_offline') == true) {
            current = const AgeEligibilityState({
              'allowed': true,
              'enforced': true,
              'online_required': false,
              'age_band': 'adult',
            });
          }
        } catch (_) {
          /* Keep private features locked. */
        }
      }
    }
    notifyListeners();
  }

  Future<void> requirePrivateAccess() async {
    if (!enabled) return;
    if (current?.onlineRequired != false ||
        current?.data['enforced'] != true ||
        current == null) {
      await refresh();
    }
    if (blocked) {
      throw StateError(
        'Complete age, guardian and consent requirements online before using private features.',
      );
    }
  }

  Future<void> submit(String path, Map<String, dynamic> data) async {
    await ApiClient().post(path, data: data);
    await refresh();
  }

  Future<void> updateResidence(String country) async {
    await ApiClient().put(
      '/me/residence',
      data: {'residence_country': country},
    );
    await refresh();
  }

  Future<void> cancelGuardian() async {
    await ApiClient().delete('/me/guardian');
    await refresh();
  }

  void restricted(Map<String, dynamic> state) {
    _denied = true;
    current = AgeEligibilityState(state);
    notifyListeners();
    if (fetch == null) {
      _clearAdultAllowance();
    }
  }

  Future<void> _clearAdultAllowance() async {
    final session = await TokenStorage().getToken();
    try {
      final settings = await LocalDbService().settingsBox();
      if (session == await TokenStorage().getToken()) {
        await settings.put('age_adult_offline', false);
      }
    } catch (_) {
      /* In-memory denial remains authoritative for this session. */
    }
  }
}

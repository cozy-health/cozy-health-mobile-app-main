import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/storage/token_storage.dart';

class NativeBillingService extends ChangeNotifier {
  NativeBillingService._();
  static final instance = NativeBillingService._();
  final _store = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  StreamSubscription<void>? _accountChanges;
  String? _owner, _token, _accountToken;
  List<ProductDetails> products = [];
  Map<String, dynamic> catalog = {};
  bool enabled = false, studentEligible = false, busy = false;
  String? message;
  Future<void> load() async {
    _accountChanges ??= LocalDbService().accountChanges.listen((_) {
      _owner = null;
      _token = null;
      _accountToken = null;
      products = [];
      catalog = {};
      enabled = false;
      studentEligible = false;
      busy = false;
      message = null;
      notifyListeners();
    });
    if (kIsWeb ||
        !{
          TargetPlatform.android,
          TargetPlatform.iOS,
        }.contains(defaultTargetPlatform)) {
      return;
    }
    _subscription ??= _store.purchaseStream.listen(
      _purchases,
      onError: (_) {
        message = 'The store is unavailable. Please retry.';
        notifyListeners();
      },
    );
    final owner = LocalDbService().activeUserId;
    final token = await TokenStorage().getToken();
    if (owner != _owner || token != _token) {
      busy = false;
    }
    if (owner == null ||
        token == null ||
        kIsWeb ||
        !{
          TargetPlatform.android,
          TargetPlatform.iOS,
        }.contains(defaultTargetPlatform)) {
      return;
    }
    final response = await ApiClient().get('/store/config');
    if (owner != LocalDbService().activeUserId ||
        token != await TokenStorage().getToken()) {
      return;
    }
    final data = Map<String, dynamic>.from(response.data as Map);
    _owner = owner;
    _token = token;
    _accountToken = data['account_token'] as String?;
    enabled = data['enabled'] == true;
    studentEligible = data['student_eligible'] == true;
    catalog = Map<String, dynamic>.from(data['products'] as Map? ?? {});
    if (!enabled || !await _store.isAvailable()) {
      enabled = false;
      message = 'Store purchases are not activated yet.';
      notifyListeners();
      return;
    }
    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'apple'
        : 'google';
    final ids = catalog.entries
        .where(
          (entry) =>
              entry.value is Map &&
              (entry.value as Map)['platform'] == platform,
        )
        .map((entry) => entry.key)
        .toSet();
    final result = await _store.queryProductDetails(ids);
    if (owner != LocalDbService().activeUserId ||
        token != await TokenStorage().getToken()) {
      return;
    }
    products = result.productDetails;
    message = result.error == null
        ? null
        : 'Some store products could not be loaded.';
    notifyListeners();
  }

  Future<void> purchase(ProductDetails product) async {
    if (!enabled ||
        busy ||
        _owner != LocalDbService().activeUserId ||
        _token != await TokenStorage().getToken() ||
        _accountToken == null) {
      return;
    }
    final info = catalog[product.id];
    if (info is Map && info['tier'] == 'student' && !studentEligible) {
      message = 'Student approval is required before purchase.';
      notifyListeners();
      return;
    }
    busy = true;
    message = null;
    notifyListeners();
    try {
      await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: product,
          applicationUserName: _accountToken,
        ),
      );
    } catch (_) {
      busy = false;
      message = 'Purchase could not start. No entitlement was granted.';
      notifyListeners();
    }
  }

  Future<void> restore() async {
    await load();
    if (!enabled || _accountToken == null) return;
    message =
        'Checking purchases with the store. Access is restored only after verification.';
    notifyListeners();
    await _store.restorePurchases(applicationUserName: _accountToken);
  }

  Future<void> _purchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        busy = true;
        notifyListeners();
        continue;
      }
      if (purchase.status == PurchaseStatus.canceled ||
          purchase.status == PurchaseStatus.error) {
        busy = false;
        message =
            'Purchase cancelled or unsuccessful. No paid access was granted.';
        notifyListeners();
        continue;
      }
      if (purchase.status != PurchaseStatus.purchased &&
          purchase.status != PurchaseStatus.restored) {
        continue;
      }
      final owner = _owner, token = _token;
      if (owner == null ||
          owner != LocalDbService().activeUserId ||
          token != await TokenStorage().getToken()) {
        continue;
      }
      try {
        final platform = defaultTargetPlatform == TargetPlatform.iOS
            ? 'apple'
            : 'google';
        final reference = platform == 'apple'
            ? purchase.purchaseID
            : purchase.verificationData.serverVerificationData;
        if (reference == null || reference.isEmpty) {
          throw StateError('No purchase reference');
        }
        await ApiClient().post(
          '/subscription/verify-receipt',
          data: {'platform': platform, 'reference': reference},
        );
        if (owner != LocalDbService().activeUserId ||
            token != await TokenStorage().getToken()) {
          continue;
        }
        if (purchase.pendingCompletePurchase) {
          await _store.completePurchase(purchase);
        }
        message =
            'Purchase verified. Your subscription status has been updated.';
      } catch (_) {
        message =
            'Verification could not finish. Retry Restore purchases; do not purchase again.';
      }
      busy = false;
      notifyListeners();
    }
  }
}

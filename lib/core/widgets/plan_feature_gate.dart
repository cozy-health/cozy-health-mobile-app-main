import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../api/api_exceptions.dart';
import '../services/plan_access_service.dart';
import '../services/local_db_service.dart';
import '../services/feature_flags_service.dart';
import '../storage/token_storage.dart';
import '../theme/cozy_colors.dart';
import 'app_pressable.dart';
import 'wellness_panel.dart';

class PlanFeatureGate extends StatefulWidget {
  const PlanFeatureGate({
    super.key,
    required this.feature,
    required this.child,
  });
  final String feature;
  final Widget child;
  @override
  State<PlanFeatureGate> createState() => _PlanFeatureGateState();
}

class _PlanFeatureGateState extends State<PlanFeatureGate>
    with WidgetsBindingObserver {
  final _owner = LocalDbService().activeUserId;
  late Future<Object?> _check;
  Timer? _expiry;
  StreamSubscription<void>? _clearing, _changes;
  int _attempt = 0;
  bool _ended = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FeatureFlagsService.instance.addListener(_refresh);
    _clearing = TokenStorage.sessionClearing.listen((_) {
      _expiry?.cancel();
      if (mounted) setState(() => _ended = true);
    });
    _changes = TokenStorage.sessionChanges.listen((_) => _refresh());
    _check = _startCheck();
  }

  Future<Object?> _startCheck() {
    _expiry?.cancel();
    final attempt = ++_attempt;
    return PlanAccessService.instance.requireUntil(widget.feature).then((
      expiry,
    ) {
      if (mounted &&
          !_ended &&
          attempt == _attempt &&
          _owner == LocalDbService().activeUserId &&
          expiry != null) {
        final remaining = expiry.difference(DateTime.now());
        _expiry = Timer(
          remaining.isNegative ? Duration.zero : remaining,
          _refresh,
        );
      }
      return null;
    }, onError: (Object error, StackTrace stack) => error);
  }

  void _refresh() {
    if (!mounted || _ended) return;
    setState(() {
      _check = _startCheck();
    });
  }

  @override
  void didUpdateWidget(covariant PlanFeatureGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feature != widget.feature) _check = _startCheck();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    _expiry?.cancel();
    _clearing?.cancel();
    _changes?.cancel();
    FeatureFlagsService.instance.removeListener(_refresh);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Object?>(
    future: _check,
    builder: (context, snapshot) {
      final error = snapshot.error ?? snapshot.data;
      if (_ended || _owner != LocalDbService().activeUserId) {
        return const SizedBox.shrink();
      }
      if (snapshot.connectionState == ConnectionState.done && error == null) {
        return widget.child;
      }
      final tokens = context.cozyColors.wellness;
      final trends = widget.feature == 'trends_dashboard';
      return Scaffold(
        appBar: AppBar(
          title: Text(trends ? 'Trends and insights' : 'Plan access'),
          leading: AppPressable(
            key: const ValueKey('plan-gate-back'),
            label: 'Back',
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
            child: SizedBox(
              width: tokens.touch,
              height: tokens.touch,
              child: const Icon(Icons.arrow_back),
            ),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.all(tokens.page),
            children: [
              if (snapshot.connectionState != ConnectionState.done)
                const Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: 'Checking plan access',
                  ),
                )
              else ...[
                if (trends) ...[
                  Text(
                    'Included with Premium and verified Student',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: tokens.small),
                ],
                Text(
                  error is ApiException
                      ? error.message
                      : 'Your plan could not be checked. Connect to the internet and retry.',
                ),
                SizedBox(height: tokens.gap),
                WellnessAction(
                  key: const ValueKey('plan-gate-retry'),
                  label: 'Retry',
                  onPressed: _refresh,
                  icon: Icons.refresh,
                ),
                SizedBox(height: tokens.small),
                WellnessAction(
                  key: const ValueKey('plan-gate-plans'),
                  label: 'View plans',
                  onPressed: () => context.push('/subscription'),
                  icon: Icons.workspace_premium_outlined,
                ),
                SizedBox(height: tokens.small),
                const Text(
                  'Purchases remain on hold. Your existing records and emergency help remain available.',
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

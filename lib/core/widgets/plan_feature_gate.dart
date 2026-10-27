import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../api/api_exceptions.dart';
import '../services/plan_access_service.dart';
import '../services/local_db_service.dart';

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

class _PlanFeatureGateState extends State<PlanFeatureGate> {
  final _owner = LocalDbService().activeUserId;
  late Future<void> _check = PlanAccessService.instance.require(widget.feature);
  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _check,
    builder: (context, snapshot) {
      if (_owner != LocalDbService().activeUserId) {
        return const SizedBox.shrink();
      }
      if (snapshot.connectionState == ConnectionState.done &&
          !snapshot.hasError) {
        return widget.child;
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Plan access')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (snapshot.connectionState != ConnectionState.done)
                const Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: 'Checking plan access',
                  ),
                )
              else ...[
                Text(
                  snapshot.error is ApiException
                      ? (snapshot.error as ApiException).message
                      : 'Your plan could not be checked. Connect to the internet and retry.',
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => setState(
                    () => _check = PlanAccessService.instance.require(
                      widget.feature,
                    ),
                  ),
                  child: const Text('Retry'),
                ),
                TextButton(
                  onPressed: () => context.push('/subscription'),
                  child: const Text('View plans'),
                ),
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

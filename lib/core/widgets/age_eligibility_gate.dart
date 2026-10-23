import 'package:flutter/widgets.dart';
import '../services/age_eligibility_service.dart';

/// Compatibility wrapper; no custom age/guardian screen or network request.
class AgeEligibilityGate extends StatelessWidget {
  const AgeEligibilityGate({
    super.key,
    required this.child,
    this.service,
    this.observeRoute = true,
    this.review = false,
  });
  final Widget child;
  final AgeEligibilityService? service;
  final bool observeRoute;
  final bool review;
  @override
  Widget build(BuildContext context) => child;
}

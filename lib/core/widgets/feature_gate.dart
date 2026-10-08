import 'package:flutter/material.dart';
import '../services/feature_flags_service.dart';

class FeatureGate extends StatelessWidget {
  const FeatureGate({
    super.key,
    required this.feature,
    required this.builder,
    this.flags,
  });
  final String feature;
  final WidgetBuilder builder;
  final FeatureFlagsService? flags;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: flags ?? FeatureFlagsService.instance,
    builder: (context, _) =>
        (flags ?? FeatureFlagsService.instance).isEnabled(feature)
        ? builder(context)
        : const Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Assistant is temporarily unavailable',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
  );
}

import 'package:flutter/material.dart';
import '../api/api_exceptions.dart';
import '../services/plan_access_service.dart';
import 'wellness_sheet.dart';
import 'wellness_panel.dart';

Future<bool> ensurePlanAccess(BuildContext context, String feature) async {
  try {
    await PlanAccessService.instance.require(feature);
    return context.mounted;
  } catch (error) {
    if (!context.mounted) return false;
    await showWellnessDialog<void>(
      context: context,
      builder: (dialogContext) => WellnessSheet(
        title: 'Check your plan',
        children: [
          Text(
            error is ApiException
                ? error.message
                : 'Your plan could not be checked. Connect to the internet and try again. Your existing records remain available.',
          ),
          WellnessAction(
            label: 'Close',
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
    return false;
  }
}

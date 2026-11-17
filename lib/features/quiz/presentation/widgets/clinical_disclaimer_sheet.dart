import 'package:flutter/material.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/widgets/wellness_sheet.dart';
import '../../../../core/widgets/wellness_panel.dart';

class ClinicalDisclaimerSheet extends StatelessWidget {
  const ClinicalDisclaimerSheet({
    super.key,
    this.disclaimer =
        'Not a substitute for professional care. This is not a diagnosis.',
  });
  final String disclaimer;
  static const acknowledgementKey = 'clinical_quiz_disclaimer_v1';
  static Future<bool?> show(BuildContext context, {String? disclaimer}) async {
    if (!context.mounted) return false;
    return showWellnessSheet<bool>(
      context: context,
      builder: (_) => ClinicalDisclaimerSheet(
        disclaimer:
            disclaimer ??
            'Not a substitute for professional care. This is not a diagnosis.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness;
    return WellnessSheet(
      title: 'Before we start',
      children: [
        Icon(
          Icons.info_outline,
          size: w.streakIcon,
          color: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(height: w.gap),
        Text(disclaimer),
        SizedBox(height: w.section),
        WellnessAction(
          key: const ValueKey('disclaimer-accept'),
          label: 'I understand',
          filled: true,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        SizedBox(height: w.small),
        WellnessAction(
          key: const ValueKey('disclaimer-cancel'),
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}

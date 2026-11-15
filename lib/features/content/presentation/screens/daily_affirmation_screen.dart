import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/data/demo_mode.dart';
import '../../../../core/services/affirmation_controller.dart';
import '../../../../core/widgets/affirmation_panel.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scroll_body.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/theme/cozy_colors.dart';

class DailyAffirmationScreen extends StatelessWidget {
  const DailyAffirmationScreen({super.key, this.controller});
  final AffirmationController? controller;

  Future<void> _copy(BuildContext context) async {
    final state = DemoMode.instance.enabled && controller == null
        ? const AffirmationState()
        : (controller ?? AffirmationController.instance).state;
    try {
      await Clipboard.setData(ClipboardData(text: state.text));
      if (context.mounted) {
        AppSnackbar.show(
          context,
          AppSnackbar.success('Affirmation copied to clipboard'),
        );
      }
    } catch (_) {
      if (context.mounted) {
        AppSnackbar.show(
          context,
          AppSnackbar.error(
            "We couldn't copy this affirmation. Please try again.",
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your affirmation')),
    body: SafeArea(
      child: AppScrollBody(
        child: Padding(
          padding: EdgeInsets.all(context.cozyColors.wellness.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.all(context.cozyColors.wellness.section),
                decoration: BoxDecoration(
                  color: context.cozyColors.wellness.accentPanel(
                    Theme.of(context).colorScheme,
                  ),
                  borderRadius: BorderRadius.circular(
                    context.cozyColors.wellness.radius,
                  ),
                ),
                child: AffirmationPanel(
                  controller: controller,
                  showReflection: true,
                ),
              ),
              SizedBox(height: context.cozyColors.wellness.section),
              AppButton(
                text: 'Copy affirmation',
                isOutlined: true,
                onPressed: () => _copy(context),
              ),
              SizedBox(height: context.cozyColors.wellness.section),
            ],
          ),
        ),
      ),
    ),
  );
}

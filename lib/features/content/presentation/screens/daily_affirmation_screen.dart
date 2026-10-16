import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/data/demo_mode.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/affirmation_controller.dart';
import '../../../../core/widgets/affirmation_panel.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scroll_body.dart';
import '../../../../core/widgets/app_snackbar.dart';

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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.favorite_outline,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              AffirmationPanel(controller: controller),
              const SizedBox(height: 32),
              const Spacer(),
              AppButton(
                text: 'Copy affirmation',
                isOutlined: true,
                onPressed: () => _copy(context),
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'Read related articles',
                onPressed: () => context.push(
                  AppRouter.categoryDetail,
                  extra: {'id': 'self-compassion', 'title': 'Self-compassion'},
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ),
  );
}

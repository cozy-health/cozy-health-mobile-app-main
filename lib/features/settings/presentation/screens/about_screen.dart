import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock 7+ days of use check
    final bool hasUsedAppFor7Days = true;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 16),
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Icon(
                    Icons.favorite,
                    size: 60,
                    color: Theme.of(context).colorScheme.primary,
                  ), // Mock logo
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Cozy Health',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading1.copyWith(
                  fontSize: 28,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Version 1.0.0 (build 42)',
                textAlign: TextAlign.center,
                style: AppTextStyles.body2.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: 300,
                  child: Text(
                    'A warm, private space for mental wellbeing.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body1.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 48),

              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  children: [
                    _AboutRow(
                      icon: Icons.star_border,
                      label: 'Our mission',
                      onTap: () => _showContentModal(
                        context,
                        'Our mission',
                        _missionText,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.4),
                      ),
                    ),
                    _AboutRow(
                      icon: Icons.eco_outlined,
                      label: 'How we\'re different',
                      onTap: () => _showContentModal(
                        context,
                        'How we\'re different',
                        _differentText,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.4),
                      ),
                    ),
                    _AboutRow(
                      icon: Icons.people_outline,
                      label: 'Team',
                      onTap: () =>
                          _showContentModal(context, 'Team', _teamText),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.4),
                      ),
                    ),
                    _AboutRow(
                      icon: Icons.description_outlined,
                      label: 'Open source licenses',
                      onTap: () {
                        // Normally this would push to the LicensePage native to Flutter
                        showLicensePage(
                          context: context,
                          applicationName: 'Cozy Health',
                          applicationVersion: '1.0.0',
                          applicationIcon: Icon(
                            Icons.favorite,
                            size: 60,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        );
                      },
                    ),
                    if (hasUsedAppFor7Days) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.4),
                        ),
                      ),
                      _AboutRow(
                        icon: Icons.thumb_up_outlined,
                        label: 'Rate Cozy Health',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Opening app store...'),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 48),
              Text(
                'Made with care.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body2.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textSubtleDark
                      : AppColors.textSubtleLight,
                ),
              ),
              SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  void _showContentModal(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 32,
              bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.heading2.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Text(
                  content,
                  style: AppTextStyles.body1.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.6,
                  ),
                ),
                SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  static const String _missionText =
      "Mental health tools shouldn't feel like productivity apps. They should feel like a quiet room, a warm cup of tea, someone who listens. Cozy Health exists to make daily reflection feel gentle — not another thing to optimize. We're not here to gamify your feelings. We're here to help you notice them.";

  static const String _differentText =
      "No streaks you can break. No ads. No upselling on your hardest days. Your journal is private by default. Your data is yours. We'll never sell it or train AI on it without your explicit permission. And if you ever need real help, we'll connect you — fast.";

  static const String _teamText =
      "Small team. Based in Lagos. Building for people who need this.";
}

class _AboutRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AboutRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.onSurface,
                size: 24,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body1.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import '../widgets/next_of_kin_panel.dart';
import '../../data/next_of_kin_repository.dart';
import 'package:cozy_health/core/widgets/app_scroll_body.dart';
import 'package:cozy_health/core/theme/app_surface.dart';
import 'package:cozy_health/core/widgets/security_blur.dart';
import '../../../../core/services/crash_reporting.dart';
import 'package:cozy_health/core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_state.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/models/safety_plan.dart';
import '../../services/crisis_detector.dart';
import '../../services/crisis_launcher.dart';
import '../../services/safety_plan_storage.dart';

const CrisisLauncher _crisisLauncher = CrisisLauncher();

bool _isDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color _crisisBg(BuildContext context) =>
    _isDark(context) ? AppColors.crisisBgDark : AppColors.crisisBg;

Color _crisisSurface(BuildContext context) =>
    _isDark(context) ? AppColors.crisisSurfaceDark : AppColors.crisisSurface;

Color _crisisSubtle(BuildContext context) =>
    _isDark(context) ? AppColors.crisisSubtleDark : AppColors.crisisSubtle;

class CrisisShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final bool showBack;

  const CrisisShell({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(24, 16, 24, 24),
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _crisisBg(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (showBack)
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(Icons.arrow_back),
                      color: Theme.of(context).colorScheme.onSurface,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                    )
                  else
                    const SizedBox(width: 48, height: 48),
                  const Spacer(),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 32),
              Text(
                title,
                style: CrisisText.h1.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 12),
                Text(
                  subtitle!,
                  style: CrisisText.bodyMuted.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 40),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class CrisisText {
  static TextStyle get h1 => AppTextStyles.heading1.copyWith(
    color: AppColors.crisisText,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1.18,
  );

  static TextStyle get h2 => AppTextStyles.heading2.copyWith(
    color: AppColors.crisisText,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.22,
  );

  static TextStyle get body => AppTextStyles.body1.copyWith(
    color: AppColors.crisisText,
    fontSize: 18,
    height: 1.45,
  );

  static TextStyle get bodyMuted => body.copyWith(
    color: AppColors.crisisTextMuted,
    fontWeight: FontWeight.w400,
  );

  static TextStyle get caption => AppTextStyles.body2.copyWith(
    color: AppColors.crisisTextMuted,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static TextStyle get button => AppTextStyles.buttonText.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
}

class CrisisButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool outlined;
  final bool textOnly;
  final Color color;

  const CrisisButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.textOnly = false,
    this.color = AppColors.crisisPrimary,
  });

  @override
  Widget build(BuildContext context) {
    if (textOnly) {
      return TextButton(
        onPressed: onPressed,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: CrisisText.body
              .copyWith(color: Theme.of(context).colorScheme.onSurface)
              .copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 64),
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withValues(alpha: 0.55)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                label,
                style: CrisisText.button.copyWith(color: color),
              ),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: color,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(label, style: CrisisText.button),
            ),
    );
  }
}

class CrisisActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;
  final bool primary;
  final bool danger;

  const CrisisActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
    this.primary = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = primary
        ? AppColors.crisisPrimary
        : danger
        ? AppSurface.tint(
            context,
            AppColors.crisisDanger.withValues(alpha: 0.1),
          )
        : Theme.of(context).colorScheme.surface;
    final fg = primary
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurface;
    final border = primary
        ? Colors.transparent
        : danger
        ? AppColors.crisisDanger.withValues(alpha: 0.3)
        : Theme.of(context).colorScheme.outline;

    return Semantics(
      button: true,
      label: '$title. $subtitle. $action.',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: Container(
          constraints: BoxConstraints(minHeight: primary ? 88 : 76),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.fromBorderSide(
              AppSurface.side(context, color: border),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: primary
                    ? Theme.of(context).colorScheme.onPrimary
                    : AppColors.crisisPrimary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: CrisisText.body
                          .copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          )
                          .copyWith(color: fg, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: CrisisText.caption
                          .copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          )
                          .copyWith(
                            color: primary
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                action,
                style: CrisisText.caption
                    .copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )
                    .copyWith(
                      color: primary
                          ? Theme.of(context).colorScheme.onPrimary
                          : AppColors.crisisPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CrisisResourcesHubScreen extends StatelessWidget {
  const CrisisResourcesHubScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      SecurityBlur(child: _buildProtected(context));

  Widget _buildProtected(BuildContext context) {
    return CrisisShell(
      title: "You're not\nalone.",
      subtitle: 'Here are people who can help right now.',
      trailing: TextButton(
        onPressed: () => context.go(AppRouter.home),
        child: Text(
          'Close',
          style: CrisisText.caption.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      children: [
        CrisisActionCard(
          icon: Icons.person_outline,
          title: 'Contact next of kin',
          subtitle: 'Reach someone you trust',
          action: 'Open',
          primary: true,
          onTap: () => context.push(AppRouter.crisisContact),
        ),
        const SizedBox(height: 32),
        _DividerLabel(label: 'More support'),
        const SizedBox(height: 24),
        _SupportRow(
          icon: Icons.assignment,
          title: 'My Safety Plan',
          subtitle: 'View or create your plan',
          onTap: () => context.push(AppRouter.safetyPlan),
        ),
        _SupportRow(
          icon: Icons.spa,
          title: 'Grounding Exercise',
          subtitle: '5-4-3-2-1',
          onTap: () => context.push(AppRouter.grounding),
        ),
        _SupportRow(
          icon: Icons.air,
          title: 'Breathing Exercise',
          subtitle: '4-7-8',
          onTap: () => context.push(AppRouter.breathing),
        ),
        _SupportRow(
          icon: Icons.local_hospital,
          title: 'Find Professional Help',
          subtitle: 'Licensed support options',
          onTap: () => context.push(AppRouter.professionalHelp),
        ),
        const SizedBox(height: 28),
        Center(
          child: Text(
            "Contacting your next of kin does not dispatch emergency assistance. This app is not a substitute for professional care.",
            textAlign: TextAlign.center,
            style: CrisisText.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _SupportRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CrisisActionCard(
        icon: icon,
        title: title,
        subtitle: subtitle,
        action: '',
        onTap: onTap,
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  final String label;

  const _DividerLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: CrisisText.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Divider(color: Theme.of(context).colorScheme.outline)),
      ],
    );
  }
}

void showCrisisCallSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String number,
  bool danger = false,
}) {
  final parentContext = context;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        decoration: BoxDecoration(
          border: AppSurface.border(context),
          color: Theme.of(context).bottomSheetTheme.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: CrisisText.h2.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: CrisisText.bodyMuted.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              CrisisButton(
                label: 'Call',
                color: danger
                    ? AppColors.crisisDanger
                    : AppColors.crisisPrimary,
                onPressed: () async {
                  Navigator.pop(context);
                  final result = await _crisisLauncher.callPhone(number);
                  if (result != LaunchResult.success && parentContext.mounted) {
                    showLaunchFailureSheet(
                      parentContext,
                      result: result,
                      value: number,
                      retry: () => _crisisLauncher.callPhone(number),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              CrisisButton(
                label: 'Cancel',
                textOnly: true,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _openCrisisUrl(BuildContext context, String url) async {
  final result = await _crisisLauncher.openUrl(url);
  if (result != LaunchResult.success && context.mounted) {
    showLaunchFailureSheet(
      context,
      result: result,
      value: url,
      retry: () => _crisisLauncher.openUrl(url),
    );
  }
}

void showLaunchFailureSheet(
  BuildContext context, {
  required LaunchResult result,
  required String value,
  required Future<LaunchResult> Function() retry,
}) {
  final headline = switch (result) {
    LaunchResult.noApp => "We couldn't open your dialer.",
    LaunchResult.invalidNumber => "That number doesn't look right.",
    LaunchResult.unknown => 'Something went wrong.',
    LaunchResult.success => 'Opened.',
  };
  final subtext = switch (result) {
    LaunchResult.invalidNumber => 'Try updating it in settings.',
    LaunchResult.unknown => 'Here is the number. You can also copy it:',
    _ => "Here's the number:",
  };

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(),
    builder: (sheetContext) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        decoration: BoxDecoration(
          border: AppSurface.border(context),
          color: Theme.of(context).bottomSheetTheme.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                headline,
                textAlign: TextAlign.center,
                style: CrisisText.h2.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtext,
                textAlign: TextAlign.center,
                style: CrisisText.bodyMuted.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              SelectableText(
                value,
                textAlign: TextAlign.center,
                style: CrisisText.h1
                    .copyWith(color: Theme.of(context).colorScheme.onSurface)
                    .copyWith(color: AppColors.crisisPrimary),
              ),
              const SizedBox(height: 24),
              CrisisButton(
                label: 'Copy number',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  HapticFeedback.mediumImpact();
                  Navigator.pop(sheetContext);
                  _showSupportSnack(context, 'Copied');
                },
              ),
              const SizedBox(height: 12),
              CrisisButton(
                label: 'Try again',
                outlined: true,
                onPressed: () async {
                  Navigator.pop(sheetContext);
                  final retryResult = await retry();
                  if (retryResult != LaunchResult.success && context.mounted) {
                    showLaunchFailureSheet(
                      context,
                      result: retryResult,
                      value: value,
                      retry: retry,
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              CrisisButton(
                label: 'Close',
                textOnly: true,
                onPressed: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showSupportSnack(BuildContext context, String message) {
  AppSnackbar.show(
    context,
    AppSnackbar.fromLegacy(
      content: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface),
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Theme.of(context).colorScheme.inverseSurface,
    ),
  );
}

class CrisisDetectionOverlayScreen extends StatelessWidget {
  const CrisisDetectionOverlayScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      SecurityBlur(child: _buildProtected(context));

  Widget _buildProtected(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(
        context,
      ).colorScheme.scrim.withValues(alpha: 0.45),
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: AppSurface.border(context),
              color: _crisisSurface(context),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: AppScrollBody(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.favorite,
                          color: AppColors.crisisWarning,
                          size: 48,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "It sounds like you're going through a lot.",
                          style: CrisisText.h2.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "You don't have to carry this alone. We're here with you.",
                          style: CrisisText.bodyMuted.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        CrisisButton(
                          label: 'Contact next of kin',
                          onPressed: () =>
                              context.push(AppRouter.crisisContact),
                        ),
                        const SizedBox(height: 12),
                        CrisisButton(
                          label: 'Try a grounding exercise',
                          outlined: true,
                          onPressed: () => context.push(AppRouter.grounding),
                        ),
                        const SizedBox(height: 12),
                        _CrisisDismissButton(
                          label: "I'm okay right now",
                          onPressed: () => context.pop(),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 24,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => context.pop(),
                    tooltip: 'Close',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showCrisisSupportOverlay(
  BuildContext context, {
  CrisisSignal signal = CrisisSignal.hard,
}) {
  final isSoft = signal == CrisisSignal.soft;

  return CrashReporting.privateOverlay(
    () => showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          shape: const RoundedRectangleBorder(),
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(
              border: AppSurface.border(context),
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.favorite,
                        color: AppColors.crisisWarning,
                        size: 48,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        isSoft
                            ? 'That sounds heavy.'
                            : "It sounds like you're going through a lot.",
                        style: CrisisText.h2.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isSoft
                            ? 'Want to talk to someone, or try a grounding exercise?'
                            : "You don't have to carry this alone. We're here with you.",
                        style: CrisisText.bodyMuted.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      CrisisButton(
                        label: 'Contact next of kin',
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          context.push(AppRouter.crisisContact);
                        },
                      ),
                      const SizedBox(height: 12),
                      CrisisButton(
                        label: isSoft
                            ? 'Try grounding'
                            : 'Try a grounding exercise',
                        outlined: true,
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          context.push(AppRouter.grounding);
                        },
                      ),
                      const SizedBox(height: 12),
                      _CrisisDismissButton(
                        label: isSoft ? "I'm okay" : "I'm okay right now",
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 24,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => Navigator.pop(dialogContext),
                    tooltip: 'Close',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _CrisisDismissButton extends StatelessWidget {
  const _CrisisDismissButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class EmergencyContactScreen extends StatelessWidget {
  const EmergencyContactScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const SecurityBlur(child: NextOfKinPanel());
}

class SafetyPlanScreen extends StatefulWidget {
  const SafetyPlanScreen({super.key});

  @override
  State<SafetyPlanScreen> createState() => _SafetyPlanScreenState();
}

class _SafetyPlanScreenState extends State<SafetyPlanScreen>
    with WidgetsBindingObserver {
  final SafetyPlanStorage _storage = SafetyPlanStorage();
  int _step = 0;
  final Set<String> _selected = {};
  bool _done = false;
  bool _loaded = false;
  SafetyPlan _plan = SafetyPlan.empty();
  Map<String, String>? _nextOfKin;
  List<Map<String, String>> _existingPeople = [];
  List<Map<String, String>> _existingProfessionals = [];

  static const _titles = [
    'What tells you\na hard moment\nis coming?',
    'What helps you\nfeel a little\nsteadier?',
    'What can take\nyour mind off\nthings?',
    'Who can you\nreach out to?',
    'Who supports\nyour care?',
    'How can your\nspace feel safer?',
  ];
  static const _subtitles = [
    'These are your early warning signs. Knowing them helps you prepare.',
    'Choose things that have helped before, even a little.',
    'Small distractions can give your mind room to breathe.',
    'These are people who care about you.',
    'Add professional support if you have it. This step is optional.',
    'Choose ways to reduce risk around you.',
  ];
  static const _options = [
    [
      'Feeling isolated',
      "Can't sleep",
      'Racing thoughts',
      'Withdrawing from people',
      'Feeling hopeless',
    ],
    [
      'Deep breathing',
      'Going for a walk',
      'Listening to music',
      'Taking a shower',
      'Journaling',
      'Calling a friend',
      'Making tea',
    ],
    [
      'Watching a comfort show',
      'Reading',
      'Cleaning',
      'Cooking',
      'Drawing',
      'Playing a game',
      'Going outside',
    ],
    ['My next of kin'],
    [
      'Therapist',
      'Psychiatrist',
      'Primary care doctor',
      'Other professional support',
    ],
    [
      'Remove or lock away medications',
      'Remove or lock away sharp objects',
      'Ask someone to hold onto items',
      'Avoid alcohol and drugs',
      'Stay with someone',
    ],
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDraft();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _storage.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _loaded && !_done) {
      _saveCurrentStep();
    }
  }

  Future<void> _loadDraft() async {
    final contact = await NextOfKinRepository().load().catchError(
      (Object _) => null,
    );
    _nextOfKin = contact == null
        ? null
        : {
            'name': contact.name,
            'phone': contact.phone,
            'relation': contact.relationship,
          };
    final saved = await _storage.load();
    if (!mounted) return;
    if (saved == null) {
      setState(() => _loaded = true);
      return;
    }

    setState(() {
      _plan = saved;
      _existingPeople = saved.peopleToCall ?? [];
      _existingProfessionals = saved.professionals ?? [];
      _step = saved.isComplete ? 0 : saved.currentStep.clamp(0, 5);
      _selected
        ..clear()
        ..addAll(_keysForStep(0, saved.warningSigns ?? []))
        ..addAll(_keysForStep(1, saved.copingStrategies ?? []))
        ..addAll(_keysForStep(2, saved.distractions ?? []))
        ..addAll(
          _keysForStep(
            3,
            (saved.peopleToCall ?? []).map((item) => item['name']!),
          ),
        )
        ..addAll(
          _keysForStep(
            4,
            (saved.professionals ?? []).map((item) => item['name']!),
          ),
        )
        ..addAll(_keysForStep(5, saved.environmentSteps ?? []));
      if (_nextOfKin != null &&
          _existingPeople.any(
            (person) => person['phone'] == _nextOfKin!['phone'],
          )) {
        _selected.add('3:My next of kin');
      }
      _loaded = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !saved.isComplete) {
        _showResumeDraftSheet(saved.currentStep);
      }
    });
  }

  Iterable<String> _keysForStep(int step, Iterable<String> values) {
    return values.map((value) => '$step:$value');
  }

  Future<void> _saveCurrentStep({bool complete = false}) async {
    final values = _options.asMap().map((index, options) {
      return MapEntry(
        index,
        options
            .where((option) => _selected.contains('$index:$option'))
            .toList(),
      );
    });

    final nextPlan = _plan.copyWith(
      warningSigns: values[0],
      copingStrategies: values[1],
      distractions: values[2],
      peopleToCall: [
        ..._existingPeople.where(
          (person) =>
              _nextOfKin == null || person['phone'] != _nextOfKin!['phone'],
        ),
        if ((values[3] ?? []).contains('My next of kin') &&
            _nextOfKin != null &&
            _nextOfKin!['phone']!.isNotEmpty)
          _nextOfKin!,
      ],
      professionals: [
        ..._existingProfessionals.where(
          (person) => !_options[4].contains(person['name']),
        ),
        ...(values[4] ?? const []).map(
          (name) => _existingProfessionals.firstWhere(
            (person) => person['name'] == name,
            orElse: () => {'name': name, 'role': name, 'phone': ''},
          ),
        ),
      ],
      environmentSteps: values[5],
      currentStep: complete ? 5 : (_step + 1).clamp(0, 5),
      isComplete: complete,
      lastUpdatedAt: DateTime.now(),
    );
    setState(() => _plan = nextPlan);
    await _storage.save(nextPlan);
  }

  void _showResumeDraftSheet(int currentStep) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          decoration: BoxDecoration(
            border: AppSurface.border(context),
            color: Theme.of(context).bottomSheetTheme.backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Continue your safety plan?',
                  textAlign: TextAlign.center,
                  style: CrisisText.h2.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You left off at Step ${currentStep + 1} of 6.',
                  textAlign: TextAlign.center,
                  style: CrisisText.bodyMuted.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                CrisisButton(
                  label: 'Continue',
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 12),
                CrisisButton(
                  label: 'Start over',
                  outlined: true,
                  color: AppColors.crisisDanger,
                  onPressed: () {
                    _confirmStartOver(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmStartOver(BuildContext sheetContext) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          scrollable: true,
          title: Text(
            'Start over?',
            style: CrisisText.h2.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          content: Text(
            'This will clear your current safety plan draft.',
            style: CrisisText.bodyMuted.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final dialogNavigator = Navigator.of(dialogContext);
                final sheetNavigator = Navigator.of(sheetContext);
                await _storage.clear();
                if (!mounted) return;
                dialogNavigator.pop();
                sheetNavigator.pop();
                setState(() {
                  _plan = SafetyPlan.empty();
                  _existingPeople = [];
                  _existingProfessionals = [];
                  _selected.clear();
                  _step = 0;
                });
              },
              child: const Text('Start over'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) =>
      SecurityBlur(child: _buildProtected(context));

  Widget _buildProtected(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        backgroundColor: _crisisBg(context),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.crisisPrimary),
        ),
      );
    }

    if (_done) {
      return CrisisShell(
        title: 'Your safety\nplan is ready.',
        subtitle: 'You can view it anytime from the home screen or settings.',
        children: [
          const Center(
            child: Icon(
              Icons.check_circle,
              color: AppColors.crisisSafe,
              size: 88,
            ),
          ),
          const SizedBox(height: 40),
          CrisisButton(
            label: 'View My Plan',
            onPressed: () => context.push(AppRouter.safetyPlanView),
          ),
          const SizedBox(height: 12),
          CrisisButton(
            label: 'Back to Home',
            outlined: true,
            onPressed: () => context.go(AppRouter.home),
          ),
        ],
      );
    }

    return CrisisShell(
      title: _titles[_step],
      subtitle: _subtitles[_step],
      trailing: Text(
        'Step ${_step + 1}/6',
        style: CrisisText.caption.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: (_step + 1) / 6,
            minHeight: 8,
            backgroundColor: _crisisSubtle(context),
            color: AppColors.crisisPrimary,
          ),
        ),
        const SizedBox(height: 28),
        if (_step == 3 && _nextOfKin == null)
          TextButton(
            onPressed: () async {
              await context.push(AppRouter.crisisContact);
              final contact = await NextOfKinRepository().load();
              if (!mounted) return;
              setState(() {
                _nextOfKin = contact == null
                    ? null
                    : {
                        'name': contact.name,
                        'phone': contact.phone,
                        'relation': contact.relationship,
                      };
              });
            },
            child: const Text('Set up next of kin'),
          ),
        if (_step == 3 && _nextOfKin != null)
          Text('${_nextOfKin!['name']} · ${_nextOfKin!['phone']}'),
        ...(_step == 3 && _nextOfKin == null ? <String>[] : _options[_step])
            .map((option) {
              final selected = _selected.contains('$_step:$option');
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PlanChip(
                  label: option,
                  selected: selected,
                  onTap: () => setState(() {
                    final key = '$_step:$option';
                    selected ? _selected.remove(key) : _selected.add(key);
                  }),
                ),
              );
            }),
        const SizedBox(height: 20),
        CrisisButton(
          label: _step == 5 ? 'Finish Plan' : 'Continue',
          onPressed: () async {
            await _saveCurrentStep(complete: _step == 5);
            if (!mounted) return;
            setState(() {
              if (_step == 5) {
                _done = true;
              } else {
                _step++;
              }
            });
          },
        ),
        const SizedBox(height: 12),
        CrisisButton(
          label: 'Save and finish later',
          textOnly: true,
          onPressed: () async {
            await _saveCurrentStep();
            if (!context.mounted) return;
            _showSupportSnack(context, 'Safety plan draft saved.');
            context.pop();
          },
        ),
      ],
    );
  }
}

class _PlanChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PlanChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? _crisisSubtle(context)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.crisisPrimary
                : Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_box : Icons.check_box_outline_blank,
              color: selected
                  ? AppColors.crisisPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: CrisisText.body.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SafetyPlanViewScreen extends StatelessWidget {
  const SafetyPlanViewScreen({super.key});
  @override
  Widget build(BuildContext context) => const PersistedSafetyPlanViewScreen();
}

class PersistedSafetyPlanViewScreen extends StatelessWidget {
  const PersistedSafetyPlanViewScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      SecurityBlur(child: _buildProtected(context));

  Widget _buildProtected(BuildContext context) {
    return FutureBuilder<SafetyPlan?>(
      future: SafetyPlanStorage().load(),
      builder: (context, snapshot) {
        final plan = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: _crisisBg(context),
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.crisisPrimary),
            ),
          );
        }

        if (plan == null) {
          return CrisisShell(
            title: 'Safety plan',
            children: [
              EmptyState(
                icon: Icons.assignment_outlined,
                title: "Create a safety plan that's just for you.",
                primaryCtaLabel: 'Create my plan',
                onPrimaryCta: () => context.push(AppRouter.safetyPlan),
              ),
            ],
          );
        }
        final sections = {
          'My warning signs': plan.warningSigns,
          'What helps me': plan.copingStrategies,
          'Distractions': plan.distractions,
          'People I can call': (plan.peopleToCall ?? [])
              .map((item) => '${item['name']} (${item['relation']})')
              .toList(),
          'Professionals': (plan.professionals ?? [])
              .map((item) => '${item['name']} (${item['role']})')
              .toList(),
          'Making my space safe': plan.environmentSteps,
        };

        return CrisisShell(
          title: 'My Safety Plan',
          subtitle: 'Last updated ${_formatPlanDate(plan.lastUpdatedAt)}',
          trailing: TextButton(
            onPressed: () => context.push(AppRouter.safetyPlan),
            child: Text(
              'Edit',
              style: CrisisText.caption.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          children: [
            ...sections.entries.map(
              (entry) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: CrisisText.body
                          .copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          )
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    if (entry.value == null || entry.value!.isEmpty)
                      Text(
                        'Nothing added yet.',
                        style: CrisisText.bodyMuted.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      ...entry.value!.map(
                        (item) => Text(
                          '- $item',
                          style: CrisisText.bodyMuted.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            CrisisButton(
              label: 'Contact next of kin',
              onPressed: () => context.push(AppRouter.crisisContact),
            ),
          ],
        );
      },
    );
  }
}

String _formatPlanDate(DateTime date) {
  final now = DateTime.now();
  if (date.year == now.year && date.month == now.month && date.day == now.day) {
    return 'today';
  }
  return '${date.month}/${date.day}/${date.year}';
}

class GroundingExerciseScreen extends StatefulWidget {
  const GroundingExerciseScreen({super.key});

  @override
  State<GroundingExerciseScreen> createState() =>
      _GroundingExerciseScreenState();
}

class _GroundingExerciseScreenState extends State<GroundingExerciseScreen> {
  int _step = 0;
  bool _done = false;

  static const _counts = [5, 4, 3, 2, 1];
  static const _senses = [
    'things you\ncan see',
    'things you\ncan touch',
    'things you\ncan hear',
    'things you\ncan smell',
    'thing you\ncan taste',
  ];
  static const _copy = [
    'Look around you. Name them slowly. There is no rush.',
    'Notice textures near you. Keep breathing.',
    'Listen gently. Let sounds come to you.',
    'Notice any scent, even a small one.',
    'Notice one taste or the feeling in your mouth.',
  ];

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return CrisisShell(
        title: 'You did it.',
        subtitle: "You're here. You're present. That's enough.",
        children: [
          const Center(
            child: Icon(
              Icons.check_circle,
              color: AppColors.crisisSafe,
              size: 88,
            ),
          ),
          const SizedBox(height: 40),
          CrisisButton(
            label: 'Back to Home',
            onPressed: () => context.go(AppRouter.home),
          ),
          const SizedBox(height: 12),
          CrisisButton(
            label: 'Contact next of kin',
            outlined: true,
            onPressed: () => context.push(AppRouter.crisisContact),
          ),
        ],
      );
    }

    final count = _counts[_step];
    return CrisisShell(
      title: _senses[_step],
      subtitle: _copy[_step],
      trailing: Text(
        'Step ${_step + 1}/5',
        style: CrisisText.caption.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      children: [
        Center(
          child: Text(
            '$count',
            style: CrisisText.h1
                .copyWith(color: Theme.of(context).colorScheme.onSurface)
                .copyWith(fontSize: 120, color: AppColors.crisisPrimary),
          ),
        ),
        const SizedBox(height: 24),
        ...List.generate(
          count,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              decoration: InputDecoration(
                hintText: '${index + 1}.',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        CrisisButton(
          label: _step == 4 ? 'Finish' : 'Next',
          onPressed: () => setState(() {
            if (_step == 4) {
              _done = true;
            } else {
              _step++;
            }
          }),
        ),
        CrisisButton(
          label: 'Skip typing, just notice them',
          textOnly: true,
          onPressed: () => setState(() {
            if (_step == 4) {
              _done = true;
            } else {
              _step++;
            }
          }),
        ),
      ],
    );
  }
}

class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key});

  @override
  State<BreathingExerciseScreen> createState() =>
      _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen> {
  int _phase = 0;
  int _cycle = 0;
  bool _paused = false;
  Timer? _timer;

  static const _labels = ['Breathe in', 'Hold', 'Breathe out', 'Pause'];
  static const _subtitles = ['through your nose', '', 'through your mouth', ''];
  static const _durations = [4, 7, 8, 1];

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (_paused || _cycle >= 4) return;
    HapticFeedback.lightImpact();
    _timer = Timer(Duration(seconds: _durations[_phase]), () {
      if (!mounted) return;
      setState(() {
        if (_phase == 3) {
          _phase = 0;
          _cycle++;
        } else {
          _phase++;
        }
      });
      _schedule();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cycle >= 4) {
      return CrisisShell(
        title: 'You did it.',
        subtitle: 'How do you feel?',
        children: [
          const Center(
            child: Icon(
              Icons.check_circle,
              color: AppColors.crisisSafe,
              size: 88,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: CrisisButton(
                  label: 'Better',
                  outlined: true,
                  onPressed: () => context.go(AppRouter.home),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CrisisButton(
                  label: 'Same',
                  outlined: true,
                  onPressed: () => context.push(AppRouter.crisisFollowUp),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          CrisisButton(
            label: 'Back to Home',
            onPressed: () => context.go(AppRouter.home),
          ),
        ],
      );
    }

    final scale = _phase == 0 || _phase == 1 ? 1.35 : 1.0;
    return CrisisShell(
      title: _labels[_phase],
      subtitle: _subtitles[_phase].isEmpty ? null : _subtitles[_phase],
      children: [
        const SizedBox(height: 40),
        Center(
          child: AnimatedScale(
            scale: scale,
            duration: Duration(seconds: _durations[_phase]),
            curve: Curves.easeInOut,
            child: Container(
              width: 200,
              height: 200,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _crisisSubtle(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.crisisPrimary, width: 2),
              ),
              child: Text(
                'Breathe',
                style: CrisisText.h2.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 80),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            4,
            (index) => Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index <= _cycle
                    ? AppColors.crisisPrimary
                    : _crisisSubtle(context),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        CrisisButton(
          label: _paused ? 'Resume' : 'Pause',
          outlined: true,
          onPressed: () => setState(() {
            _paused = !_paused;
            _schedule();
          }),
        ),
        const SizedBox(height: 12),
        CrisisButton(
          label: 'Stop',
          textOnly: true,
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}

class ProfessionalHelpScreen extends StatefulWidget {
  const ProfessionalHelpScreen({super.key});
  @override
  State<ProfessionalHelpScreen> createState() => _ProfessionalHelpScreenState();
}

class _ProfessionalHelpScreenState extends State<ProfessionalHelpScreen> {
  final _searchFocus = FocusNode();
  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CrisisShell(
      title: 'Find professional\nhelp.',
      subtitle: 'These services can connect you with licensed professionals.',
      children: [
        TextField(
          focusNode: _searchFocus,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search by name or location',
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        EmptyState(
          icon: Icons.person_search_outlined,
          title: 'Search for providers near you.',
          primaryCtaLabel: 'Search providers',
          onPrimaryCta: () => _searchFocus.requestFocus(),
        ),
        _SupportRow(
          icon: Icons.place,
          title: 'Therapists near me',
          subtitle: 'In-person sessions',
          onTap: () => _openCrisisUrl(
            context,
            'https://www.psychologytoday.com/us/therapists',
          ),
        ),
        _SupportRow(
          icon: Icons.video_call,
          title: 'Online therapy',
          subtitle: 'Video sessions',
          onTap: () => _openCrisisUrl(context, 'https://findtreatment.gov/'),
        ),
        _SupportRow(
          icon: Icons.local_hospital,
          title: 'Psychiatry',
          subtitle: 'Medication support',
          onTap: () => _openCrisisUrl(context, 'https://findtreatment.gov/'),
        ),
        _SupportRow(
          icon: Icons.emergency,
          title: 'Contact next of kin',
          subtitle: 'Immediate help',
          onTap: () => context.push(AppRouter.crisisContact),
        ),
        const SizedBox(height: 28),
        Center(
          child: Text(
            "Cozy Health doesn't endorse or profit from any of these services.",
            textAlign: TextAlign.center,
            style: CrisisText.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class CrisisFollowUpScreen extends StatefulWidget {
  const CrisisFollowUpScreen({super.key});

  @override
  State<CrisisFollowUpScreen> createState() => _CrisisFollowUpScreenState();
}

class _CrisisFollowUpScreenState extends State<CrisisFollowUpScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return CrisisShell(
      title: 'Just checking in.',
      subtitle: 'How are you doing today?',
      showBack: false,
      children: [
        const Center(
          child: Icon(Icons.favorite, color: AppColors.crisisWarning, size: 72),
        ),
        const SizedBox(height: 32),
        ...['Better than yesterday', 'About the same', 'Still struggling'].map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlanChip(
              label: option,
              selected: _selected == option,
              onTap: () => setState(() => _selected = option),
            ),
          ),
        ),
        const SizedBox(height: 28),
        CrisisButton(
          label: 'Continue',
          onPressed: _selected == null
              ? null
              : () {
                  if (_selected == 'Still struggling') {
                    context.push(AppRouter.crisisContact);
                  } else {
                    _showSupportSnack(
                      context,
                      "Thanks for checking in. We're here.",
                    );
                    context.go(AppRouter.home);
                  }
                },
        ),
        CrisisButton(
          label: 'Skip',
          textOnly: true,
          onPressed: () => context.go(AppRouter.home),
        ),
      ],
    );
  }
}

void showQuickCalmSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        decoration: BoxDecoration(
          border: AppSurface.border(context),
          color: Theme.of(context).bottomSheetTheme.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'I need a moment.',
                style: CrisisText.h2.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'What would help right now?',
                style: CrisisText.bodyMuted.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              _SupportRow(
                icon: Icons.air,
                title: 'Breathe',
                subtitle: '4-7-8',
                onTap: () {
                  Navigator.pop(context);
                  context.push(AppRouter.breathing);
                },
              ),
              _SupportRow(
                icon: Icons.spa,
                title: 'Ground',
                subtitle: '5-4-3-2-1',
                onTap: () {
                  Navigator.pop(context);
                  context.push(AppRouter.grounding);
                },
              ),
              _SupportRow(
                icon: Icons.call,
                title: 'Call someone',
                subtitle: 'People who can help right now',
                onTap: () {
                  Navigator.pop(context);
                  context.push(AppRouter.crisisContact);
                },
              ),
              CrisisButton(
                label: 'Close',
                textOnly: true,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    },
  );
}

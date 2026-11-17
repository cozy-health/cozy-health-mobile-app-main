import 'package:cozy_health/core/theme/app_surface.dart';
import 'package:cozy_health/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../services/network_status.dart';

/// Connectivity is observed once by NetworkObserver; dismissal lasts this run.
class OfflineStatusBanner extends StatefulWidget {
  const OfflineStatusBanner({super.key, required this.onRetry});
  final VoidCallback onRetry;
  @override
  State<OfflineStatusBanner> createState() => _OfflineStatusBannerState();
}

class _OfflineStatusBannerState extends State<OfflineStatusBanner> {
  static bool _dismissed = false;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool?>(
    valueListenable: networkOffline,
    builder: (context, offline, _) {
      final dark = Theme.of(context).brightness == Brightness.dark;
      final visible = offline == true && !_dismissed;
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      return AnimatedSwitcher(
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        transitionBuilder: (child, animation) => SizeTransition(
          sizeFactor: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, -.1),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
        ),
        child: !visible
            ? const SizedBox.shrink()
            : Padding(
                key: const ValueKey('home-offline'),
                padding: const EdgeInsets.only(bottom: 16),
                child: Material(
                  color: dark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  shape: AppSurface.shape(context, BorderRadius.circular(12)),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_off,
                          color: dark ? AppColors.warning : AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "You're offline. Changes will sync when you reconnect.",
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: dark
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ),
                        Semantics(
                          label: 'Retry connection',
                          button: true,
                          child: IconButton(
                            tooltip: Overlay.maybeOf(context) == null
                                ? null
                                : 'Retry connection',
                            onPressed: widget.onRetry,
                            icon: const Icon(Icons.refresh),
                          ),
                        ),
                        Semantics(
                          label: 'Dismiss offline banner',
                          button: true,
                          child: IconButton(
                            tooltip: Overlay.maybeOf(context) == null
                                ? null
                                : 'Dismiss offline banner',
                            onPressed: () => setState(() => _dismissed = true),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      );
    },
  );
}

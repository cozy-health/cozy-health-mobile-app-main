import 'package:flutter/material.dart';
import '../services/network_status.dart';

/// A shared, scroll-safe invitation for an empty screen or card.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon,
    this.illustrationAsset,
    required this.title,
    this.subtitle,
    this.primaryCtaLabel,
    this.onPrimaryCta,
    this.onOfflineRetry,
  });

  final IconData? icon;
  final String? illustrationAsset;
  final String title;
  final String? subtitle;
  final String? primaryCtaLabel;
  final VoidCallback? onPrimaryCta;
  final VoidCallback? onOfflineRetry;

  @override
  Widget build(BuildContext context) {
    if (onOfflineRetry != null) {
      return ValueListenableBuilder<bool?>(
        valueListenable: networkOffline,
        child: _build(context),
        builder: (context, offline, child) => offline == true
            ? EmptyState(
                icon: Icons.cloud_off,
                title: "You're offline.",
                subtitle: 'Connect to load your data, then try again.',
                primaryCtaLabel: 'Try again',
                onPrimaryCta: onOfflineRetry,
              )
            : child!,
      );
    }
    return _build(context);
  }

  Widget _build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (illustrationAsset != null)
            Image.asset(
              illustrationAsset!,
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            )
          else
            Icon(
              icon ?? Icons.favorite_border,
              size: 120,
              color: colors.primary,
            ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
          if (primaryCtaLabel != null && onPrimaryCta != null) ...[
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: FilledButton(
                onPressed: onPrimaryCta,
                child: Text(primaryCtaLabel!, textAlign: TextAlign.center),
              ),
            ),
          ],
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedHeight) return Center(child: content);
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: content),
          ),
        );
      },
    );
  }
}

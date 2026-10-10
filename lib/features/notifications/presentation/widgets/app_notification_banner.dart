import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

class AppNotificationBanner extends StatefulWidget {
  final String icon;
  final String title;
  final String body;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final bool isTop;

  const AppNotificationBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
    required this.onDismiss,
    this.isTop = true,
  });

  @override
  State<AppNotificationBanner> createState() => _AppNotificationBannerState();
}

class _AppNotificationBannerState extends State<AppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation =
        Tween<Offset>(
          begin: widget.isTop ? const Offset(0, -1) : const Offset(0, 1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );

    _controller.forward();

    // Auto dismiss
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.isTop ? MediaQuery.of(context).padding.top + 16 : null,
      bottom: widget.isTop ? null : MediaQuery.of(context).padding.bottom + 80,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _controller,
          child: Dismissible(
            key: const Key('notification_banner'),
            direction: widget.isTop
                ? DismissDirection.up
                : DismissDirection.down,
            onDismissed: (_) => widget.onDismiss(),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  widget.onTap();
                  _dismiss();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.icon, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              style: AppTextStyles.body1.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.body,
                              style: AppTextStyles.body2.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        onPressed: _dismiss,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

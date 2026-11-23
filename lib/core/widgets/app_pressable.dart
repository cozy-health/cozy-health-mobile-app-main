import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/cozy_colors.dart';
import '../utils/haptics.dart';
import '../utils/motion.dart';

/// Branded touch and keyboard activation with platform-native press feedback.
class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.child,
    this.onPressed,
    this.label,
    this.selected,
    this.checked,
    this.expanded,
    this.haptic = true,
  });
  final Widget child;
  final VoidCallback? onPressed;
  final String? label;
  final bool? selected, checked, expanded;
  final bool haptic;
  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false, _focused = false;

  void _handleTap() {
    if (widget.onPressed == null) return;
    if (widget.haptic) AppHaptics.selection();
    widget.onPressed!.call();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.cozyColors.recording;
    final enabled = widget.onPressed != null;
    final reduced = shouldReduceMotion(context);
    final platform = Theme.of(context).platform;
    final isApple =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    final duration = reduced ? Duration.zero : tokens.pressDuration;

    return Semantics(
      excludeSemantics: widget.label != null,
      button: true,
      enabled: enabled,
      label: widget.label,
      selected: widget.selected,
      checked: widget.checked,
      expanded: widget.expanded,
      onTap: widget.onPressed,
      child: FocusableActionDetector(
        enabled: enabled,
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _handleTap();
              return null;
            },
          ),
        },
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        child: GestureDetector(
          excludeFromSemantics: true,
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? _handleTap : null,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: (_) {
            if (_pressed) setState(() => _pressed = false);
          },
          onTapCancel: () {
            if (_pressed) setState(() => _pressed = false);
          },
          child: AnimatedScale(
            scale: _pressed && enabled && !reduced ? tokens.pressScale : 1,
            duration: duration,
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: _pressed && enabled && !reduced && isApple ? 0.72 : 1.0,
              duration: duration,
              curve: Curves.easeOutCubic,
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(tokens.controlRadius),
                  border: _focused
                      ? Border.all(
                          color: tokens.controlColor(
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.surface,
                            Theme.of(context).colorScheme.onSurface,
                            minimumContrast: 3,
                          ),
                          width: tokens.selectedBorder,
                        )
                      : null,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: tokens.touch,
                    minHeight: tokens.touch,
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

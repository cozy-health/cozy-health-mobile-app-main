import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/cozy_colors.dart';
import '../utils/motion.dart';

/// Branded touch and keyboard activation without Material ink overlays.
class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.child,
    this.onPressed,
    this.label,
    this.selected,
    this.checked,
    this.expanded,
  });
  final Widget child;
  final VoidCallback? onPressed;
  final String? label;
  final bool? selected, checked, expanded;
  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false, _focused = false;
  @override
  Widget build(BuildContext context) {
    final tokens = context.cozyColors.recording;
    final enabled = widget.onPressed != null;
    final reduced = shouldReduceMotion(context);
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
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        child: GestureDetector(
          excludeFromSemantics: true,
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed && enabled && !reduced ? tokens.pressScale : 1,
            duration: reduced ? Duration.zero : tokens.pressDuration,
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
    );
  }
}

import 'dart:async';
import '../storage/token_storage.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/cozy_colors.dart';
import 'app_pressable.dart';
import 'wellness_panel.dart';

Future<T?> showWellnessSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool dismissible = true,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  isDismissible: dismissible,
  enableDrag: dismissible,
  backgroundColor: Theme.of(context).colorScheme.surface,
  barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: .32),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(context.cozyColors.wellness.radius),
    ),
  ),
  clipBehavior: Clip.antiAlias,
  builder: (context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: builder(context),
  ),
);

/// Centred task dialog using the same tokens and scroll behavior as sheets.
Future<T?> showWellnessDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool dismissible = true,
}) => showDialog<T>(
  context: context,
  barrierDismissible: dismissible,
  builder: (context) => Dialog(
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(context.cozyColors.wellness.radius),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    clipBehavior: Clip.antiAlias,
    child: _SessionDialogScope(builder: builder),
  ),
);

class _SessionDialogScope extends StatefulWidget {
  const _SessionDialogScope({required this.builder});
  final WidgetBuilder builder;
  @override
  State<_SessionDialogScope> createState() => _SessionDialogScopeState();
}

class _SessionDialogScopeState extends State<_SessionDialogScope> {
  StreamSubscription<void>? _clearing, _changes;
  bool _ended = false;
  @override
  void initState() {
    super.initState();
    _clearing = TokenStorage.sessionClearing.listen((_) => _end());
    _changes = TokenStorage.sessionChanges.listen((_) => _end());
  }

  void _end() {
    if (!mounted || _ended) return;
    setState(() => _ended = true);
    final route = ModalRoute.of(context);
    if (route != null && route.isActive) {
      Navigator.of(context).removeRoute(route);
    }
  }

  @override
  void dispose() {
    _clearing?.cancel();
    _changes?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _ended ? const SizedBox.shrink() : widget.builder(context);
}

/// The entire task scrolls so its actions stay reachable with large text/IME.
class WellnessSheet extends StatelessWidget {
  const WellnessSheet({
    super.key,
    required this.title,
    required this.children,
    this.onClose,
    this.busy = false,
    this.controller,
    this.footer,
  });
  final Widget? footer;
  final ScrollController? controller;
  final String title;
  final List<Widget> children;
  final VoidCallback? onClose;
  final bool busy;
  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness, c = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !busy,
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, box) {
            final available = box.hasBoundedHeight
                ? box.maxHeight
                : MediaQuery.sizeOf(context).height -
                      MediaQuery.viewInsetsOf(context).bottom;
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: math.max(0, available * .9),
                maxWidth: 560,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      controller: controller,
                      padding: EdgeInsets.all(w.page),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(top: w.small),
                                  child: Text(
                                    title,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall,
                                  ),
                                ),
                              ),
                              Tooltip(
                                message: 'Close',
                                excludeFromSemantics: true,
                                child: AppPressable(
                                  key: const ValueKey('wellness-sheet-close'),
                                  label: 'Close $title',
                                  onPressed: busy
                                      ? null
                                      : onClose ?? () => Navigator.pop(context),
                                  child: SizedBox(
                                    width: w.touch,
                                    height: w.touch,
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: c.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: w.contentGap),
                          ...children,
                        ],
                      ),
                    ),
                  ),
                  if (footer != null)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: w.page,
                        vertical: w.small,
                      ),
                      child: footer!,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class WellnessSheetOption extends StatelessWidget {
  const WellnessSheetOption({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.subtitle,
    this.selected,
    this.destructive = false,
  });
  final String label;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool? selected;
  final bool destructive;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context),
        c = t.colorScheme,
        w = context.cozyColors.wellness;
    final ink = destructive
        ? context.cozyColors.recording.controlColor(
            c.error,
            c.surface,
            c.onSurface,
          )
        : wellnessAccentInk(context);
    return Padding(
      padding: EdgeInsets.only(bottom: w.small),
      child: AppPressable(
        label: subtitle == null ? label : '$label. $subtitle',
        selected: selected,
        onPressed: onPressed,
        child: Container(
          constraints: BoxConstraints(minHeight: w.touch),
          padding: EdgeInsets.all(w.contentGap),
          decoration: BoxDecoration(
            color: selected == true ? w.accentPanel(c) : c.surface,
            border: Border.all(
              color: selected == true ? ink : c.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(w.tileRadius),
          ),
          child: Row(
            children: [
              Icon(icon, color: ink),
              SizedBox(width: w.contentGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: t.textTheme.titleSmall?.copyWith(
                        color: destructive ? ink : c.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: w.tight),
                      Text(subtitle!, style: t.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              if (selected == true) ...[
                SizedBox(width: w.small),
                Icon(Icons.check_rounded, color: ink),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class WellnessDestructiveAction extends StatelessWidget {
  const WellnessDestructiveAction({
    super.key,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme, w = context.cozyColors.wellness;
    final foreground = context.cozyColors.recording.controlColor(
      c.onError,
      c.error,
      c.error.computeLuminance() > .179 ? Colors.black : Colors.white,
    );
    return AppPressable(
      label: label,
      onPressed: onPressed,
      child: Container(
        alignment: Alignment.center,
        constraints: BoxConstraints(minHeight: w.touch),
        padding: EdgeInsets.all(w.contentGap),
        decoration: BoxDecoration(
          color: onPressed == null ? c.surface : c.error,
          border: Border.all(color: c.outlineVariant),
          borderRadius: BorderRadius.circular(w.tileRadius),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: onPressed == null ? c.onSurfaceVariant : foreground,
          ),
        ),
      ),
    );
  }
}

Future<bool> confirmWellnessAction(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  String cancel = 'Cancel',
  void Function(Route<dynamic>?)? onRoute,
}) async {
  final result = await showWellnessDialog<bool>(
    context: context,
    builder: (context) {
      onRoute?.call(ModalRoute.of(context));
      return WellnessSheet(
        title: title,
        children: [
          Text(message),
          SizedBox(height: context.cozyColors.wellness.gap),
          WellnessAction(
            label: cancel,
            onPressed: () => Navigator.pop(context, false),
          ),
          SizedBox(height: context.cozyColors.wellness.small),
          WellnessDestructiveAction(
            label: action,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      );
    },
  );
  return result == true;
}

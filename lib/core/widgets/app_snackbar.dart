import 'wellness_sheet.dart';
import 'wellness_panel.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_surface.dart';
import 'package:go_router/go_router.dart';
import '../routing/app_router.dart';
import '../services/local_db_service.dart';
import '../utils/motion.dart';

enum _NoticeKind { success, error, info, warning }

class AppSnackbar {
  static bool _syncDialogOpen = false;
  static OverlayEntry? _entry;
  static VoidCallback? _dismissCurrent;
  static void dismiss() => _dismissCurrent?.call();
  static SnackBar saved({required String type, required String id}) => success(
    LocalDbService().hasPending(type, id)
        ? 'Saved locally — will sync when online'
        : 'Saved',
  );
  static final _failures = <String, int>{};
  static String friendly(String message) {
    if (RegExp(
      r'Exception|Socket|DioError|SQLSTATE|https?://|StackTrace|\bError:',
      caseSensitive: false,
    ).hasMatch(message)) {
      return "We couldn't complete that. Check your connection and try again.";
    }
    return message.replaceFirst(
      RegExp(r"^(Failed to|Unable to)", caseSensitive: false),
      "We couldn't",
    );
  }

  static SnackBar success(String message) =>
      _Notice(Text(message), _NoticeKind.success);
  static SnackBar error(String message, {VoidCallback? onRetry}) => _Notice(
    Text(friendly(message)),
    _NoticeKind.error,
    action: onRetry == null
        ? null
        : SnackBarAction(label: 'Try again', onPressed: onRetry),
  );
  static SnackBar info(String message) =>
      _Notice(Text(message), _NoticeKind.info);
  static SnackBar warning(String message) =>
      _Notice(Text(message), _NoticeKind.warning);

  // Retains existing action callbacks while bringing older surfaces into one style.
  static SnackBar fromLegacy({
    required Widget content,
    SnackBarAction? action,
    Duration? duration,
    Color? backgroundColor,
    SnackBarBehavior? behavior,
    double? elevation,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    ShapeBorder? shape,
    double? width,
    VoidCallback? onVisible,
    bool? showCloseIcon,
    Color? closeIconColor,
    double? actionOverflowThreshold,
    DismissDirection? dismissDirection,
    Clip? clipBehavior,
  }) {
    final text = content is Text ? content.data ?? '' : '';
    final isError = RegExp(
      r"couldn.t|unable|failed|error|can.t|could not",
      caseSensitive: false,
    ).hasMatch(text);
    final kind = isError
        ? _NoticeKind.error
        : RegExp(
            r'saved|sent|deleted|copied|updated|ready',
            caseSensitive: false,
          ).hasMatch(text)
        ? _NoticeKind.success
        : _NoticeKind.info;
    return _Notice(
      content is Text ? Text(friendly(text)) : content,
      kind,
      action: action,
    );
  }

  static void show(BuildContext context, SnackBar snack) {
    final message = snack.content is Text
        ? (snack.content as Text).data ?? ''
        : '';
    if (message.contains('will sync') ||
        message.contains('Changes will sync')) {
      if (!_syncDialogOpen) {
        _syncDialogOpen = true;
        unawaited(
          showWellnessDialog<void>(
            context: context,
            builder: (context) => WellnessSheet(
              title: 'Saved on this device',
              children: [
                const Text('Your saved changes will sync when you reconnect.'),
                WellnessAction(
                  label: 'Got it',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ).whenComplete(() => _syncDialogOpen = false),
        );
      }
      return;
    }
    if (snack is! _Notice) {
      snack = fromLegacy(content: snack.content, action: snack.action);
    }
    final route =
        ModalRoute.of(context)?.settings.name ??
        context.widget.runtimeType.toString();
    var failures = _failures[route] ?? 0;
    if (snack is _Notice) {
      if (snack.kind == _NoticeKind.error) {
        failures++;
      } else if (snack.kind == _NoticeKind.success) {
        failures = 0;
      }
      _failures[route] = failures;
      snack = _Notice(
        snack.message,
        snack.kind,
        action: snack.action,
        support: failures >= 3 && snack.kind == _NoticeKind.error
            ? () => context.push(AppRouter.helpSupport)
            : null,
        outline: AppSurface.shape(context, BorderRadius.circular(16)),
      );
    }
    final overlay =
        AppRouter.navigatorKey.currentState?.overlay ??
        Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _dismissCurrent?.call();
    final notice = snack;
    late final OverlayEntry entry;
    var removed = false;
    void dismiss() {
      if (removed) return;
      removed = true;
      if (overlay.mounted) entry.remove();
      if (_entry == entry) {
        _entry = null;
        _dismissCurrent = null;
      }
    }

    entry = OverlayEntry(
      builder: (_) => _TopNotice(snack: notice, onDismiss: dismiss),
    );
    _entry = entry;
    _dismissCurrent = dismiss;
    overlay.insert(entry);
  }
}

/// One top position for app notices, independent of the selected tab/keyboard.
class _TopNotice extends StatefulWidget {
  const _TopNotice({required this.snack, required this.onDismiss});
  final SnackBar snack;
  final VoidCallback onDismiss;
  @override
  State<_TopNotice> createState() => _TopNoticeState();
}

class _TopNoticeState extends State<_TopNotice> {
  Timer? _timer;
  bool _started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!MediaQuery.accessibleNavigationOf(context)) {
      _timer = Timer(widget.snack.duration, widget.onDismiss);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Positioned(
      top: 0,
      left: 16,
      right: 16,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Semantics(
            liveRegion: true,
            child: Material(
              key: const Key('app-top-notice'),
              color: colors.inverseSurface,
              elevation: 4,
              shape: widget.snack.shape,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * .6,
                ),
                child: SingleChildScrollView(
                  child: DefaultTextStyle(
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: colors.onInverseSurface,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: widget.snack.content),
                          if (widget.snack.action case final action?)
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: colors.onInverseSurface,
                              ),
                              onPressed: () {
                                widget.onDismiss();
                                action.onPressed();
                              },
                              child: Text(action.label),
                            ),
                          IconButton(
                            tooltip: 'Dismiss notification',
                            onPressed: widget.onDismiss,
                            icon: Icon(
                              Icons.close,
                              color: colors.onInverseSurface,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _Notice extends SnackBar {
  _Notice(
    this.message,
    this.kind, {
    super.action,
    VoidCallback? support,
    ShapeBorder? outline,
  }) : super(
         duration: const Duration(milliseconds: 3000),
         elevation: 3,
         behavior: SnackBarBehavior.floating,
         shape:
             outline ??
             RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
         content: Builder(
           builder: (context) => TweenAnimationBuilder<double>(
             tween: Tween(begin: 0, end: 1),
             duration: motionDuration(
               context,
               const Duration(milliseconds: 150),
             ),
             curve: Curves.easeInOut,
             builder: (_, value, child) =>
                 Opacity(opacity: value, child: child),
             child: Row(
               children: [
                 Icon(switch (kind) {
                   _NoticeKind.success => Icons.check_circle_outline,
                   _NoticeKind.error => Icons.error_outline,
                   _NoticeKind.info => Icons.info_outline,
                   _NoticeKind.warning => Icons.warning_amber_rounded,
                 }, color: Theme.of(context).colorScheme.onInverseSurface),
                 const SizedBox(width: 12),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       if (kind == _NoticeKind.error)
                         const Text(
                           "Let's try that again.",
                           style: TextStyle(fontWeight: FontWeight.w600),
                         ),
                       message,
                       if (support != null)
                         TextButton(
                           onPressed: support,
                           child: Text(
                             'Help & Support',
                             style: TextStyle(
                               color: Theme.of(
                                 context,
                               ).colorScheme.onInverseSurface,
                             ),
                           ),
                         ),
                     ],
                   ),
                 ),
               ],
             ),
           ),
         ),
       );
  final Widget message;
  final _NoticeKind kind;
}

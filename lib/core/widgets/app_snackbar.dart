import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routing/app_router.dart';
import '../services/local_db_service.dart';
import '../utils/motion.dart';

enum _NoticeKind { success, error, info, warning }

class AppSnackbar {
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
      );
    }
    final media = MediaQuery.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        snack,
        snackBarAnimationStyle:
            media.disableAnimations || media.accessibleNavigation
            ? AnimationStyle.noAnimation
            : null,
      );
  }
}

class _Notice extends SnackBar {
  _Notice(this.message, this.kind, {super.action, VoidCallback? support})
    : super(
        duration: const Duration(milliseconds: 3000),
        elevation: 3,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Builder(
          builder: (context) => TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: motionDuration(
              context,
              const Duration(milliseconds: 150),
            ),
            curve: Curves.easeInOut,
            builder: (_, value, child) => Opacity(opacity: value, child: child),
            child: Row(
              children: [
                Icon(
                  switch (kind) {
                    _NoticeKind.success => Icons.check_circle_outline,
                    _NoticeKind.error => Icons.error_outline,
                    _NoticeKind.info => Icons.info_outline,
                    _NoticeKind.warning => Icons.warning_amber_rounded,
                  },
                  color: Theme.of(
                    context,
                  ).snackBarTheme.contentTextStyle?.color,
                ),
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
                              ).snackBarTheme.contentTextStyle?.color,
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

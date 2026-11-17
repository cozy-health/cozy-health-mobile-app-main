import 'package:flutter/material.dart';
import '../theme/app_surface.dart';

/// Uses the same outlined, elevated surface as the app's other popups.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.entries,
    required this.onChanged,
    this.label,
    this.compact = false,
    this.width,
  });

  final T value;
  final List<DropdownMenuEntry<T>> entries;
  final ValueChanged<T?>? onChanged;
  final Widget? label;
  final bool compact;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DropdownMenu<T>(
      key: ValueKey(value),
      initialSelection: value,
      dropdownMenuEntries: entries,
      onSelected: onChanged,
      enabled: onChanged != null,
      label: label,
      width: width,
      expandedInsets: width == null ? EdgeInsets.zero : null,
      requestFocusOnTap: false,
      enableSearch: false,
      menuHeight: MediaQuery.sizeOf(context).height * .5,
      textStyle: theme.textTheme.bodyLarge,
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
          theme.dialogTheme.backgroundColor,
        ),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        side: WidgetStatePropertyAll(AppSurface.side(context)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: compact
          ? theme.inputDecorationTheme.copyWith(
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            )
          : null,
    );
  }
}

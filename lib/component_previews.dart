import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_button.dart';
import 'core/widgets/skeleton_loader.dart';
import 'core/widgets/startup_cover.dart';

Widget componentPreviewFrame(Widget child) => MaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  home: Scaffold(
    body: SafeArea(
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    ),
  ),
);

void previewAction() {}

@Preview(
  name: 'Primary action',
  group: 'Actions',
  size: Size(320, 160),
  wrapper: componentPreviewFrame,
)
@Preview(
  name: 'Primary action dark',
  group: 'Actions',
  brightness: Brightness.dark,
  size: Size(320, 160),
  wrapper: componentPreviewFrame,
)
@Preview(
  name: 'Primary action large text',
  group: 'Actions',
  textScaleFactor: 2,
  size: Size(320, 220),
  wrapper: componentPreviewFrame,
)
Widget primaryActionPreview() => const Center(
  child: AppButton(text: 'Save changes', onPressed: previewAction),
);

@Preview(
  name: 'Disabled action',
  group: 'Actions',
  size: Size(320, 160),
  wrapper: componentPreviewFrame,
)
Widget disabledActionPreview() =>
    const Center(child: AppButton(text: 'Save changes'));

@Preview(
  name: 'Pending action',
  group: 'Actions',
  size: Size(320, 160),
  wrapper: componentPreviewFrame,
)
Widget pendingActionPreview() =>
    const Center(child: AppButton(text: 'Save changes', isLoading: true));

@Preview(
  name: 'Secondary action',
  group: 'Actions',
  size: Size(320, 160),
  wrapper: componentPreviewFrame,
)
Widget secondaryActionPreview() => const Center(
  child: AppButton(text: 'Cancel', isOutlined: true, onPressed: previewAction),
);

@Preview(
  name: 'Content loading',
  group: 'Loading',
  size: Size(375, 667),
  wrapper: componentPreviewFrame,
)
Widget loadingPreview() => const ScreenSkeleton();

@Preview(
  name: 'Launch icon',
  group: 'Startup',
  size: Size(375, 667),
  wrapper: componentPreviewFrame,
)
Widget launchPreview() => const Center(child: StartupIcon());

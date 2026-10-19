import 'package:cozy_health/core/theme/app_colors.dart';
import 'package:cozy_health/core/theme/app_surface.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/widgets/app_snackbar.dart';
import 'package:cozy_health/core/widgets/app_dropdown.dart';
import 'package:cozy_health/features/assistant/presentation/widgets/chat_shared_widgets.dart';
import 'package:cozy_health/features/crisis/presentation/screens/crisis_screens.dart';
import 'package:cozy_health/features/home/presentation/widgets/home_quiz_card.dart';
import 'package:cozy_health/features/home/presentation/widgets/journaling_card.dart';
import 'package:cozy_health/features/quiz/presentation/widgets/quiz_back_confirm_dialog.dart';
import 'package:cozy_health/features/community/presentation/widgets/report_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/local_fonts.dart';
import '../../support/surface_capture.dart';

void main() {
  setUpAll(installLocalTestFonts);
  tearDownAll(resetLocalTestFonts);

  for (final dark in [false, true]) {
    for (final contrast in [false, true]) {
      for (final accent in AppColors.brandPalette) {
        testWidgets(
          'surfaces and overlays dark=$dark contrast=$contrast accent=$accent',
          (tester) async {
            tester.view.physicalSize = const Size(390, 844);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(tester.view.resetViewInsets);
            var theme = dark ? AppTheme.dark : AppTheme.light;
            theme = theme.copyWith(
              colorScheme: theme.colorScheme.copyWith(
                primary: accent,
                onPrimary: accent.computeLuminance() > .179
                    ? Colors.black
                    : Colors.white,
              ),
            );
            if (contrast) theme = AppTheme.highContrast(theme);
            String? dropdownValue;
            await tester.pumpWidget(
              MaterialApp(
                theme: theme,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(highContrast: contrast),
                  child: RepaintBoundary(key: surfaceCaptureKey, child: child!),
                ),
                home: Scaffold(
                  body: Builder(
                    builder: (context) => ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const HomeQuizCard(),
                        const SizedBox(height: 16),
                        const JournalingCard(),
                        const SizedBox(height: 16),
                        WarmPanel(
                          color: accent.withValues(alpha: .08),
                          borderColor: accent.withValues(alpha: .15),
                          child: const Text('Tinted panel'),
                        ),
                        TextButton(
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) => const QuizBackConfirmDialog(),
                          ),
                          child: const Text('Open dialog'),
                        ),
                        TextButton(
                          onPressed: () => showModalBottomSheet<void>(
                            context: context,
                            builder: (_) => const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('Sheet content'),
                            ),
                          ),
                          child: const Text('Open sheet'),
                        ),
                        PopupMenuButton<String>(
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'review',
                              child: Text('Menu content'),
                            ),
                          ],
                          child: const Text('Open menu'),
                        ),
                        TextButton(
                          onPressed: () => showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 9, minute: 0),
                          ),
                          child: const Text('Open time'),
                        ),
                        TextButton(
                          onPressed: () => showDatePicker(
                            context: context,
                            initialDate: DateTime(2026, 10, 14),
                            firstDate: DateTime(2026),
                            lastDate: DateTime(2027),
                          ),
                          child: const Text('Open date'),
                        ),
                        TextButton(
                          onPressed: () => AppSnackbar.show(
                            context,
                            AppSnackbar.info('Saved'),
                          ),
                          child: const Text('Open notice'),
                        ),
                        AppDropdown<String>(
                          value: 'first',
                          entries: const [
                            DropdownMenuEntry(value: 'first', label: 'First'),
                            DropdownMenuEntry(value: 'second', label: 'Second'),
                          ],
                          onChanged: (value) => dropdownValue = value,
                        ),
                        TextButton(
                          onPressed: () =>
                              ReportSheet.show(context, onSubmit: () {}),
                          child: const Text('Open report'),
                        ),
                        TextButton(
                          onPressed: () => showCrisisCallSheet(
                            context,
                            title: 'Call support?',
                            subtitle: 'Support is available',
                            number: '988',
                          ),
                          child: const Text('Open call'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            for (final type in [HomeQuizCard, JournalingCard]) {
              final finder = find.descendant(
                of: find.byType(type),
                matching: find.byWidgetPredicate(
                  (w) => w is Container && w.decoration is BoxDecoration,
                ),
              );
              final decoration =
                  tester.widget<Container>(finder.first).decoration!
                      as BoxDecoration;
              final border = decoration.border! as Border;
              expect(border.top.color, theme.colorScheme.outline);
              expect(border.top.width, contrast ? 2 : 1);
              if (dark && !contrast) {
                expect(
                  decoration.color,
                  isNot(theme.scaffoldBackgroundColor),
                  reason: 'Dark card must remain visible',
                );
              }
            }
            final context = tester.element(find.byType(HomeQuizCard));
            final panel =
                tester
                        .widget<Container>(
                          find
                              .descendant(
                                of: find.byType(WarmPanel),
                                matching: find.byWidgetPredicate(
                                  (w) =>
                                      w is Container &&
                                      w.decoration is BoxDecoration,
                                ),
                              )
                              .first,
                        )
                        .decoration!
                    as BoxDecoration;
            expect(panel.color!.a, 1);
            expect((panel.border! as Border).top.color.a, 1);
            if (contrast) {
              expect(
                (panel.border! as Border).top.color,
                theme.colorScheme.outline,
              );
            }
            expect(AppSurface.tint(context, accent.withValues(alpha: .1)).a, 1);
            final name =
                'surfaces_${dark ? 'dark' : 'light'}_${contrast ? 'contrast' : 'normal'}_${accent.toARGB32()}';
            await captureSurface(tester, name);

            for (final kind in ['dialog', 'sheet', 'menu', 'time', 'date']) {
              await tester.ensureVisible(find.text('Open $kind'));
              await tester.tap(find.text('Open $kind'));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              if (kind == 'dialog') {
                final dialog = tester.widget<AlertDialog>(
                  find.byType(AlertDialog),
                );
                final shape = dialog.shape! as RoundedRectangleBorder;
                expect(shape.side.color, theme.colorScheme.outline);
                expect(
                  dialog.backgroundColor,
                  theme.dialogTheme.backgroundColor,
                );
              }
              await captureSurface(tester, '${name}_$kind');
              final navigator = tester.state<NavigatorState>(
                find.byType(Navigator).first,
              );
              navigator.pop();
              await tester.pumpAndSettle();
            }
            await tester.ensureVisible(find.text('Open notice'));
            await tester.tap(find.text('Open notice'));
            await tester.pumpAndSettle();
            final snack = tester.widget<Material>(
              find.byKey(const Key('app-top-notice')),
            );
            expect(
              (snack.shape! as RoundedRectangleBorder).side.color,
              theme.colorScheme.outline,
            );
            expect(
              (snack.shape! as RoundedRectangleBorder).side.width,
              contrast ? 2 : 1,
            );
            await captureSurface(tester, '${name}_notice');
            tester
                .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
                .hideCurrentSnackBar();
            await tester.pumpAndSettle();
            await tester.ensureVisible(find.byType(AppDropdown<String>));
            await tester.tap(find.byType(AppDropdown<String>));
            await tester.pumpAndSettle();
            expect(find.text('Second'), findsOneWidget);
            final dropdown = tester.widget<DropdownMenu<String>>(
              find.byType(DropdownMenu<String>),
            );
            expect(
              dropdown.menuStyle!.side!.resolve({})!.color,
              theme.colorScheme.outline,
            );
            await captureSurface(tester, '${name}_dropdown');
            await tester.tap(find.text('Second'));
            await tester.pumpAndSettle();
            expect(dropdownValue, 'second');
            await tester.ensureVisible(find.text('Open report'));
            await tester.tap(find.text('Open report'));
            await tester.pumpAndSettle();
            tester.view.viewInsets = const FakeViewPadding(bottom: 300);
            await tester.pumpAndSettle();
            final notes = find.descendant(
              of: find.byType(ReportSheet),
              matching: find.byType(TextField),
            );
            await tester.ensureVisible(notes);
            await tester.pumpAndSettle();
            await tester.enterText(notes, 'Review notes');
            await tester.pumpAndSettle();
            expect(tester.getRect(notes).bottom, lessThanOrEqualTo(544));
            await captureSurface(tester, '${name}_report_keyboard');
            tester.state<NavigatorState>(find.byType(Navigator).first).pop();
            await tester.pumpAndSettle();
            tester.view.resetViewInsets();
            await tester.pumpAndSettle();
            await tester.ensureVisible(find.text('Open call'));
            await tester.tap(find.text('Open call'));
            await tester.pumpAndSettle();
            expect(find.text('Call support?'), findsOneWidget);
            await captureSurface(tester, '${name}_call_sheet');
            tester.state<NavigatorState>(find.byType(Navigator).first).pop();
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}

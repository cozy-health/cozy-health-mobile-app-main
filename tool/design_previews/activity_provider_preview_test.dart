// Design review fixture only. Not imported by the application or its routes.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/theme/app_colors.dart';
import 'package:cozy_health/core/theme/cozy_colors.dart';
import 'package:cozy_health/core/widgets/app_pressable.dart';
import 'package:cozy_health/core/widgets/bottom_navigation_bar.dart';
import '../../test/support/local_fonts.dart';

const output = 'docs/design/activity-provider-proposal';
const captureKey = ValueKey('proposal-capture');
const contentKey = ValueKey('proposal-content');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await installLocalTestFonts(
      visualFontPath: 'test/golden_assets/Outfit.ttf',
      useRealFonts: true,
    );
    await Directory(output).create(recursive: true);
  });
  tearDownAll(resetLocalTestFonts);
  for (final dark in [false, true]) {
    for (final accent in [0, 1, 2, 3]) {
      for (final screen in [
        'activity',
        'messages',
        if (accent == 0) ...['history', 'resources', 'connect', 'pending'],
      ]) {
        testWidgets('proposal $screen dark=$dark accent=$accent', (
          tester,
        ) async {
          tester.view.devicePixelRatio = 2;
          tester.view.physicalSize = const Size(750, 1624);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final theme = AppTheme.withAccent(
            dark ? AppTheme.dark : AppTheme.light,
            AppColors.brandPalette[accent],
          );
          await tester.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: theme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              ),
              home: RepaintBoundary(
                key: captureKey,
                child: ProposalScreen(screen: screen),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final name =
              '$screen-${dark ? 'dark' : 'light'}-${['blue', 'green', 'orange', 'yellow'][accent]}';
          await capture(tester, name);
          if (screen == 'activity' && accent == 0) {
            final height = tester.getSize(find.byKey(contentKey)).height + 134;
            tester.view.physicalSize = Size(750, height * 2);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await capture(tester, '$name-full');
            tester.view.physicalSize = const Size(750, 1624);
            await tester.pumpAndSettle();
            await tester.ensureVisible(find.text('Recommended for you'));
            await tester.pumpAndSettle();
            await capture(tester, '$name-articles');
          }
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }
  for (final screen in [
    'activity',
    'messages',
    'history',
    'resources',
    'connect',
  ]) {
    testWidgets('large type proposal $screen', (tester) async {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(640, 1624);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final theme = AppTheme.highContrast(
        AppTheme.withAccent(AppTheme.dark, AppColors.brandPalette[3]),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(2),
              highContrast: true,
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: RepaintBoundary(
            key: captureKey,
            child: ProposalScreen(screen: screen),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture(tester, '$screen-large-contrast');
      if (screen == 'messages') {
        tester.view.physicalSize = const Size(1334, 750);
        tester.view.viewInsets = const FakeViewPadding(bottom: 360);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await capture(tester, 'messages-landscape-keyboard');
      }
      if (screen == 'activity') {
        await tester.ensureVisible(find.text('Recommended for you'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('articles-single-column')),
          findsOneWidget,
        );
        await capture(tester, 'activity-large-articles');
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

Future<void> capture(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(captureKey),
  );
  await tester.runAsync(() async {
    final img = await boundary.toImage(pixelRatio: 2);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw StateError('No PNG for $name');
    await File('$output/$name.png').writeAsBytes(data.buffer.asUint8List());
    img.dispose();
  });
}

class ProposalScreen extends StatelessWidget {
  const ProposalScreen({super.key, required this.screen});
  final String screen;
  @override
  Widget build(BuildContext context) {
    final activity = screen == 'activity';
    final w = context.cozyColors.wellness;
    final theme = Theme.of(context);
    final canvas = w.canvas(
      theme.brightness,
      MediaQuery.highContrastOf(context),
    );
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      backgroundColor: canvas,
      bottomNavigationBar: keyboard
          ? null
          : CustomBottomNavigationBar(
              currentIndex: activity ? 1 : 2,
              onTap: (_) {},
            ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: w.page,
                vertical: w.small,
              ),
              child: Row(
                children: [
                  Text('9:41', style: theme.textTheme.labelMedium),
                  const Spacer(),
                  const Icon(Icons.signal_cellular_alt_rounded, size: 16),
                  SizedBox(width: w.tight),
                  const Icon(Icons.wifi_rounded, size: 16),
                  SizedBox(width: w.tight),
                  const Icon(Icons.battery_full_rounded, size: 18),
                ],
              ),
            ),
            Expanded(
              child: activity
                  ? const ActivityProposal()
                  : ProviderProposal(screen: screen),
            ),
          ],
        ),
      ),
    );
  }
}

// All surface colours and spacing derive from the existing CozyHealth theme.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.tinted = false});
  final Widget child;
  final bool tinted;
  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness, c = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w.gap),
      decoration: BoxDecoration(
        color: tinted ? w.accentPanel(c) : c.surface,
        borderRadius: BorderRadius.circular(w.radius),
        border: Border.all(color: c.outlineVariant),
      ),
      child: child,
    );
  }
}

Widget copy(
  BuildContext context,
  String text, {
  bool muted = false,
  bool strong = false,
  double? size,
}) {
  final t = Theme.of(context);
  return Text(
    text,
    style: t.textTheme.bodyMedium?.copyWith(
      fontSize: size,
      height: 1.35,
      fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
      color: muted ? t.colorScheme.onSurfaceVariant : t.colorScheme.onSurface,
    ),
  );
}

Widget action(
  BuildContext context,
  String label, {
  bool filled = false,
  IconData? icon,
}) {
  final w = context.cozyColors.wellness, c = Theme.of(context).colorScheme;
  return AppPressable(
    onPressed: () {},
    label: label,
    child: Container(
      constraints: BoxConstraints(minHeight: w.touch),
      padding: EdgeInsets.symmetric(
        horizontal: w.contentGap,
        vertical: w.small,
      ),
      decoration: BoxDecoration(
        color: filled ? c.primary : c.surface,
        borderRadius: BorderRadius.circular(w.tileRadius),
        border: Border.all(color: filled ? c.primary : c.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: filled ? c.onPrimary : c.onSurface),
            SizedBox(width: w.small),
          ],
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: filled ? c.onPrimary : c.onSurface,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class Segments extends StatelessWidget {
  const Segments({super.key, required this.labels, required this.selected});
  final List<String> labels;
  final int selected;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme, w = context.cozyColors.wellness;
    final large = MediaQuery.textScalerOf(context).scale(14) > 21;
    Widget item(int i) => AppPressable(
      selected: i == selected,
      onPressed: () {},
      child: Container(
        constraints: BoxConstraints(minHeight: w.touch),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: w.small, vertical: w.small),
        decoration: BoxDecoration(
          color: i == selected ? c.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(w.tileRadius),
        ),
        child: Text(
          labels[i],
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: w.label,
            color: i == selected ? c.onPrimary : c.onSurface,
          ),
        ),
      ),
    );
    return Container(
      padding: EdgeInsets.all(w.tight),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.outlineVariant),
        borderRadius: BorderRadius.circular(w.tileRadius + w.tight),
      ),
      child: large
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [for (var i = 0; i < labels.length; i++) item(i)],
              ),
            )
          : Row(
              children: [
                for (var i = 0; i < labels.length; i++)
                  Expanded(child: item(i)),
              ],
            ),
    );
  }
}

class ActivityProposal extends StatelessWidget {
  const ActivityProposal({super.key});
  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness,
        t = Theme.of(context),
        c = t.colorScheme;
    Widget heading(String title) => Padding(
      padding: EdgeInsets.only(top: w.sectionSpacing, bottom: w.contentGap),
      child: Text(
        title,
        style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(w.page, w.small, w.page, w.sectionSpacing),
        child: Column(
          key: contentKey,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your activity',
              style: t.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: w.tight),
            copy(context, 'A little perspective on your week.', muted: true),
            SizedBox(height: w.sectionSpacing),
            const Segments(labels: ['Week', 'Month', 'Year'], selected: 0),
            SizedBox(height: w.contentGap),
            Row(
              children: [
                Expanded(
                  child: copy(context, '16–22 October 2026', strong: true),
                ),
                const Icon(Icons.calendar_today_outlined, size: 20),
              ],
            ),
            SizedBox(height: w.contentGap),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  copy(context, 'AVERAGE INTENSITY', muted: true, size: 12),
                  SizedBox(height: w.small),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: w.small,
                    children: [
                      Text(
                        '3.2',
                        style: t.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      copy(context, '/ 5', muted: true),
                    ],
                  ),
                  copy(
                    context,
                    '0.4 lower than the previous week',
                    muted: true,
                  ),
                  SizedBox(height: w.gap),
                  SizedBox(
                    height: 168,
                    child: CustomPaint(
                      size: const Size(double.infinity, 168),
                      painter: IntensityChart(c, t.textTheme.bodySmall),
                    ),
                  ),
                  SizedBox(height: w.contentGap),
                  Wrap(
                    spacing: w.gap,
                    runSpacing: w.small,
                    children: [
                      legend(context, 'This week', false),
                      legend(context, 'Previous week', true),
                    ],
                  ),
                  SizedBox(height: w.contentGap),
                  copy(
                    context,
                    'Intensity measures strength, from 1 to 5. Gaps mean no check-in.',
                    muted: true,
                    size: 12,
                  ),
                ],
              ),
            ),
            heading('Your check-in rhythm'),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  copy(context, '5 check-ins · 7 days', strong: true),
                  SizedBox(height: w.contentGap),
                  Row(
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                ['F', 'S', 'S', 'M', 'T', 'W', 'T'][i],
                                style: t.textTheme.labelSmall,
                              ),
                              SizedBox(height: w.small),
                              Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i == 2 || i == 5
                                      ? c.surface
                                      : w.accentPanel(c),
                                  border: Border.all(
                                    color: i == 6
                                        ? c.onSurface
                                        : c.outlineVariant,
                                  ),
                                ),
                                child: Icon(
                                  i == 2 || i == 5
                                      ? Icons.remove_rounded
                                      : Icons.check_rounded,
                                  size: 16,
                                ),
                              ),
                              SizedBox(height: w.tight),
                              Text('${16 + i}', style: t.textTheme.labelSmall),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: w.contentGap),
            Panel(
              tinted: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.edit_note_rounded, size: 28),
                  SizedBox(width: w.contentGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        copy(context, 'A 3-day writing streak', strong: true),
                        SizedBox(height: w.tight),
                        copy(
                          context,
                          'Your current streak, as of today.',
                          muted: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            heading('Common causes'),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  copy(context, 'Mentioned across 5 check-ins', muted: true),
                  SizedBox(height: w.gap),
                  for (final row in [
                    ('Work', 3),
                    ('Sleep', 2),
                    ('Relationships', 1),
                  ]) ...[
                    Row(
                      children: [
                        Expanded(child: copy(context, row.$1, strong: true)),
                        copy(context, '${row.$2} of 5', muted: true),
                      ],
                    ),
                    SizedBox(height: w.small),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(w.small),
                      child: LinearProgressIndicator(
                        value: row.$2 / 5,
                        minHeight: 6,
                        color: c.primary,
                        backgroundColor: c.outlineVariant,
                      ),
                    ),
                    SizedBox(height: w.contentGap),
                  ],
                  copy(
                    context,
                    'A check-in can include more than one cause.',
                    muted: true,
                    size: 12,
                  ),
                ],
              ),
            ),
            heading('Recommended for you'),
            copy(context, 'A few thoughtful reads for your day.', muted: true),
            SizedBox(height: w.contentGap),
            const ArticleGrid(),
            SizedBox(height: w.sectionSpacing),
            action(
              context,
              'View all articles',
              icon: Icons.arrow_forward_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

Widget legend(BuildContext context, String label, bool dashed) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    CustomPaint(
      size: const Size(24, 12),
      painter: LineSwatch(Theme.of(context).colorScheme, dashed),
    ),
    const SizedBox(width: 8),
    copy(context, label, muted: true, size: 12),
  ],
);

class LineSwatch extends CustomPainter {
  LineSwatch(this.colors, this.dashed);
  final ColorScheme colors;
  final bool dashed;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = (dashed ? colors.onSurfaceVariant : colors.primary)
      ..strokeWidth = 2;
    for (double x = 0; x < size.width; x += dashed ? 8 : size.width) {
      canvas.drawLine(
        Offset(x, 6),
        Offset(math.min(x + (dashed ? 4 : size.width), size.width), 6),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant LineSwatch oldDelegate) => true;
}

class IntensityChart extends CustomPainter {
  IntensityChart(this.colors, this.style);
  final ColorScheme colors;
  final TextStyle? style;
  @override
  void paint(Canvas canvas, Size size) {
    final left = 24.0,
        right = size.width - 8,
        top = 10.0,
        bottom = size.height - 28;
    Offset point(int i, double value) => Offset(
      left + i * (right - left) / 6,
      bottom - (value - 1) * (bottom - top) / 4,
    );
    void text(String text, Offset pos) {
      final p = TextPainter(
        text: TextSpan(
          text: text,
          style: style?.copyWith(color: colors.onSurfaceVariant, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      p.paint(canvas, pos);
      p.dispose();
    }

    for (var v = 1; v <= 5; v++) {
      final y = point(0, v.toDouble()).dy;
      canvas.drawLine(
        Offset(left, y),
        Offset(right, y),
        Paint()
          ..color = colors.outlineVariant
          ..strokeWidth = 1,
      );
      text('$v', Offset(0, y - 7));
    }
    const previous = [4.0, 3.0, 4.0, 3.0, 4.0, 3.0, 4.0];
    for (var i = 0; i < 6; i++) {
      final a = point(i, previous[i]), b = point(i + 1, previous[i + 1]);
      for (double d = 0; d < 1; d += .19) {
        canvas.drawLine(
          Offset.lerp(a, b, d)!,
          Offset.lerp(a, b, math.min(d + .09, 1))!,
          Paint()
            ..color = colors.onSurfaceVariant
            ..strokeWidth = 1.5,
        );
      }
    }
    const current = <double?>[3, 4, null, 3, 2, null, 4];
    for (var i = 0; i < 7; i++) {
      text('${16 + i}', Offset(point(i, 1).dx - 6, bottom + 12));
      final value = current[i];
      if (value == null) continue;
      if (i > 0 && current[i - 1] != null) {
        canvas.drawLine(
          point(i - 1, current[i - 1]!),
          point(i, value),
          Paint()
            ..color = colors.primary
            ..strokeWidth = 2.5,
        );
      }
      canvas.drawCircle(point(i, value), 4, Paint()..color = colors.primary);
      canvas.drawCircle(point(i, value), 2, Paint()..color = colors.surface);
    }
  }

  @override
  bool shouldRepaint(covariant IntensityChart oldDelegate) => true;
}

class ArticleGrid extends StatelessWidget {
  const ArticleGrid({super.key});
  static const titles = [
    'Mental Health 101: Understanding Anxiety, Depression, and Stress',
    'Balancing Productivity and Mental Health: How to Avoid Burnout',
    'The Link Between Diet, Exercise, and Mental Health',
    'The Role of Gratitude in Improving Mental Health',
  ];
  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness,
        t = Theme.of(context),
        c = t.colorScheme;
    Widget card(int i) => AppPressable(
      onPressed: () {},
      label: titles[i],
      child: Container(
        padding: EdgeInsets.all(w.contentGap),
        decoration: BoxDecoration(
          color: w.accentPanel(c),
          borderRadius: BorderRadius.circular(w.tileRadius),
          border: Border.all(color: c.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 64,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ArticleArt(index: i),
              ),
            ),
            SizedBox(height: w.contentGap),
            copy(context, titles[i], strong: true),
            const Spacer(),
            SizedBox(height: w.contentGap),
            Row(
              children: [
                copy(context, 'Read article', muted: true, size: 12),
                const Spacer(),
                const Icon(Icons.arrow_outward_rounded, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, box) {
        final single =
            box.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(14) > 21;
        final width = single ? box.maxWidth : (box.maxWidth - w.contentGap) / 2;
        final textHeight = titles
            .map((title) {
              final p = TextPainter(
                text: TextSpan(
                  text: title,
                  style: t.textTheme.bodyMedium?.copyWith(
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                textDirection: TextDirection.ltr,
                textScaler: MediaQuery.textScalerOf(context),
              )..layout(maxWidth: width - w.contentGap * 2);
              final h = p.height;
              p.dispose();
              return h;
            })
            .reduce(math.max);
        final labelHeight = MediaQuery.textScalerOf(context).scale(16);
        final height = 64 + w.contentGap * 4 + textHeight + labelHeight + 8;
        return Wrap(
          key: single
              ? const ValueKey('articles-single-column')
              : const ValueKey('articles-two-columns'),
          spacing: w.contentGap,
          runSpacing: w.contentGap,
          children: [
            for (var i = 0; i < 4; i++)
              SizedBox(width: width, height: height, child: card(i)),
          ],
        );
      },
    );
  }
}

class ArticleArt extends StatelessWidget {
  const ArticleArt({super.key, required this.index});
  final int index;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    if (index == 0) {
      return Image.asset(
        'assets/png/home_quiz_brain.png',
        width: 64,
        height: 64,
        fit: BoxFit.contain,
      );
    }
    if (index == 1) {
      return SizedBox(
        width: 64,
        height: 64,
        child: CustomPaint(painter: BalanceDial(c)),
      );
    }
    return SizedBox(
      width: 110,
      child: FittedBox(
        alignment: Alignment.centerLeft,
        fit: BoxFit.contain,
        child: Text(
          index == 2 ? 'LET’S TALK\nMENTAL\nHEALTH' : 'Mental\nhealth\nmatters',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            height: .94,
            letterSpacing: -.6,
            color: c.onSurface,
          ),
        ),
      ),
    );
  }
}

class BalanceDial extends CustomPainter {
  BalanceDial(this.c);
  final ColorScheme c;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 8; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 27),
        i * math.pi / 4 + .04,
        math.pi / 4 - .09,
        false,
        Paint()
          ..color = c.primary.withValues(alpha: .15 + (i % 3) * .15)
          ..strokeWidth = 10
          ..style = PaintingStyle.stroke,
      );
    }
    canvas.drawLine(
      center,
      center + const Offset(-4, -14),
      Paint()
        ..color = c.onSurface
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      center,
      center + const Offset(10, 7),
      Paint()
        ..color = c.onSurface
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 3, Paint()..color = c.onSurface);
  }

  @override
  bool shouldRepaint(covariant BalanceDial oldDelegate) => true;
}

class ProviderProposal extends StatelessWidget {
  const ProviderProposal({super.key, required this.screen});
  final String screen;
  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness, t = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).height < 450;
    final large = MediaQuery.textScalerOf(context).scale(w.label) > 21;
    if (screen == 'connect' || screen == 'pending') {
      return SingleChildScrollView(
        padding: EdgeInsets.all(w.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              large ? 'Provider' : 'Your provider',
              style: t.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: w.sectionSpacing),
            Panel(
              tinted: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.handshake_outlined, size: 40),
                  SizedBox(height: w.gap),
                  Text(
                    screen == 'pending'
                        ? 'Invitation pending'
                        : 'Care, connected.',
                    style: t.textTheme.headlineSmall,
                  ),
                  SizedBox(height: w.small),
                  copy(
                    context,
                    screen == 'pending'
                        ? 'Your invitation has been sent. We’ll let you know when your provider accepts.'
                        : 'Connect with your provider to send messages and share the records you choose.',
                    muted: true,
                  ),
                  SizedBox(height: w.sectionSpacing),
                  action(
                    context,
                    screen == 'pending'
                        ? 'Review invitation'
                        : 'Connect a provider',
                    filled: true,
                  ),
                ],
              ),
            ),
            SizedBox(height: w.sectionSpacing),
            copy(context, 'You choose what to share', strong: true),
            SizedBox(height: w.small),
            copy(
              context,
              'Connecting a provider does not automatically share your mood records or journal entries.',
              muted: true,
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        if (!compact)
          Padding(
            padding: EdgeInsets.fromLTRB(w.page, w.small, w.page, w.contentGap),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    large ? 'Provider' : 'Your provider',
                    style: t.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AppPressable(
                  label: 'Connection and sharing settings',
                  onPressed: () {},
                  child: SizedBox(
                    width: w.touch,
                    height: w.touch,
                    child: const Icon(Icons.tune_rounded),
                  ),
                ),
              ],
            ),
          ),
        if (!compact)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w.page),
            child: Panel(
              child: Row(
                children: [
                  Container(
                    width: w.touch,
                    height: w.touch,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: w.accentPanel(t.colorScheme),
                      shape: BoxShape.circle,
                    ),
                    child: copy(context, 'AM', strong: true),
                  ),
                  SizedBox(width: w.contentGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        copy(context, 'Alex Morgan', strong: true),
                        copy(
                          context,
                          large ? 'Connected' : 'Connected provider',
                          muted: true,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.unfold_more_rounded, size: 20),
                ],
              ),
            ),
          ),
        if (!compact)
          Padding(
            padding: EdgeInsets.fromLTRB(
              w.page,
              w.contentGap,
              w.page,
              w.contentGap,
            ),
            child: Segments(
              labels: const ['Messages', 'Shared', 'Resources'],
              selected: screen == 'history'
                  ? 1
                  : screen == 'resources'
                  ? 2
                  : 0,
            ),
          ),
        Expanded(
          child: screen == 'history'
              ? const HistoryProposal()
              : screen == 'resources'
              ? const ResourcesProposal()
              : const MessageConversation(),
        ),
        if (screen == 'messages') const MessageComposer(),
      ],
    );
  }
}

class MessageConversation extends StatelessWidget {
  const MessageConversation({super.key});
  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: w.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: w.gap),
              child: copy(context, 'Today · 22 October', muted: true, size: 12),
            ),
          ),
          const MessageBubble(
            text:
                'Hello. What would you like to focus on at our next appointment?',
            time: '12:00',
          ),
          SizedBox(height: w.contentGap),
          const MessageBubble(
            text:
                'I’d like to talk about my sleep and what has helped this week.',
            time: '12:03 · Sent',
            outgoing: true,
          ),
          SizedBox(height: w.contentGap),
          const MessageBubble(
            text:
                'Of course. You can share any check-ins you’d like us to discuss.',
            time: '12:05',
          ),
          SizedBox(height: w.gap),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.text,
    required this.time,
    this.outgoing = false,
  });
  final String text, time;
  final bool outgoing;
  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness, c = Theme.of(context).colorScheme;
    return Align(
      alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: .88,
        child: Column(
          crossAxisAlignment: outgoing
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(w.contentGap),
              decoration: BoxDecoration(
                color: outgoing ? w.accentPanel(c) : c.surface,
                border: Border.all(color: c.outlineVariant),
                borderRadius: BorderRadius.circular(w.tileRadius),
              ),
              child: copy(context, text),
            ),
            SizedBox(height: w.tight),
            copy(context, time, muted: true, size: 12),
          ],
        ),
      ),
    );
  }
}

class MessageComposer extends StatelessWidget {
  const MessageComposer({super.key});
  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness, c = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    if (size.width > size.height) {
      Widget icon(IconData glyph, String label, {bool enabled = true}) =>
          AppPressable(
            label: label,
            onPressed: enabled ? () {} : null,
            child: SizedBox(
              width: w.touch,
              height: w.touch,
              child: Icon(
                glyph,
                color: enabled ? c.onSurface : c.onSurfaceVariant,
              ),
            ),
          );
      return Container(
        padding: EdgeInsets.symmetric(horizontal: w.page, vertical: w.small),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.all(w.small),
                decoration: BoxDecoration(
                  border: Border.all(color: c.outlineVariant),
                  borderRadius: BorderRadius.circular(w.tileRadius),
                ),
                child: copy(context, 'Write a message…', muted: true),
              ),
            ),
            SizedBox(width: w.small),
            icon(Icons.add_rounded, 'Share records'),
            icon(Icons.mic_none_rounded, 'Record voice message'),
            icon(Icons.arrow_upward_rounded, 'Send message', enabled: false),
          ],
        ),
      );
    }
    return Container(
      padding: EdgeInsets.fromLTRB(w.page, w.small, w.page, w.small),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(minHeight: w.touch),
            padding: EdgeInsets.all(w.contentGap),
            decoration: BoxDecoration(
              border: Border.all(color: c.outlineVariant),
              borderRadius: BorderRadius.circular(w.tileRadius),
            ),
            width: double.infinity,
            child: copy(context, 'Write a message…', muted: true),
          ),
          SizedBox(height: w.small),
          Row(
            children: [
              Expanded(
                child: MediaQuery.textScalerOf(context).scale(w.label) > 21
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: AppPressable(
                          label: 'Share records',
                          onPressed: () {},
                          child: SizedBox(
                            width: w.touch,
                            height: w.touch,
                            child: const Icon(Icons.add_rounded),
                          ),
                        ),
                      )
                    : action(context, 'Share records', icon: Icons.add_rounded),
              ),
              SizedBox(width: w.small),
              AppPressable(
                label: 'Record voice message',
                onPressed: () {},
                child: SizedBox(
                  width: w.touch,
                  height: w.touch,
                  child: const Icon(Icons.mic_none_rounded),
                ),
              ),
              SizedBox(width: w.small),
              Semantics(
                button: true,
                enabled: false,
                label: 'Send message',
                child: Container(
                  width: w.touch,
                  height: w.touch,
                  decoration: BoxDecoration(
                    color: c.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(w.tileRadius),
                  ),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: c.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HistoryProposal extends StatelessWidget {
  const HistoryProposal({super.key});
  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(w.page, 0, w.page, w.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          copy(context, 'Shared history', strong: true),
          SizedBox(height: w.tight),
          copy(context, 'Only records you choose appear here.', muted: true),
          SizedBox(height: w.gap),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.folder_open_outlined, size: 28),
                SizedBox(height: w.contentGap),
                copy(context, '2 mood check-ins', strong: true),
                SizedBox(height: w.small),
                copy(
                  context,
                  'Feelings, intensity and selected causes.',
                  muted: true,
                ),
                SizedBox(height: w.gap),
                action(
                  context,
                  'Review shared records',
                  icon: Icons.arrow_forward_rounded,
                ),
              ],
            ),
          ),
          SizedBox(height: w.gap),
          action(
            context,
            'Share more records',
            filled: true,
            icon: Icons.add_rounded,
          ),
        ],
      ),
    );
  }
}

class ResourcesProposal extends StatelessWidget {
  const ResourcesProposal({super.key});
  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(w.page, 0, w.page, w.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          copy(context, 'From your provider', strong: true),
          SizedBox(height: w.tight),
          copy(context, 'Keep helpful exercises in one place.', muted: true),
          SizedBox(height: w.gap),
          Panel(
            tinted: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy(context, 'TO TRY', muted: true, size: 12),
                SizedBox(height: w.contentGap),
                const Icon(Icons.air_rounded, size: 32),
                SizedBox(height: w.contentGap),
                copy(context, 'A breathing exercise', strong: true),
                SizedBox(height: w.small),
                copy(context, 'Shared by Alex Morgan', muted: true),
                SizedBox(height: w.gap),
                action(context, 'Open exercise', filled: true),
                SizedBox(height: w.small),
                action(context, 'Not for me'),
              ],
            ),
          ),
          SizedBox(height: w.sectionSpacing),
          copy(context, 'Completed', strong: true),
          SizedBox(height: w.contentGap),
          Panel(
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded),
                SizedBox(width: w.contentGap),
                Expanded(
                  child: copy(context, 'Grounding exercise', strong: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

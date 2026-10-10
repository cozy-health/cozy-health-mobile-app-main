import 'package:cozy_health/core/models/mood_entry.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/features/home/presentation/widgets/cozy_calendar.dart';
import 'package:cozy_health/features/home/presentation/widgets/journaling_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/local_fonts.dart';

void main() {
  setUpAll(installLocalTestFonts);
  tearDownAll(resetLocalTestFonts);
  for (final size in [
    const Size(375, 667),
    const Size(412, 892),
    const Size(667, 375),
  ]) {
    for (final dark in [false, true]) {
      testWidgets('Home cards scroll without clipping at $size, dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final now = DateTime(2026, 10, 10, 9, 31);
        final entries = List.generate(
          3,
          (i) => MoodEntry(
            id: '$i',
            mood: 'calm',
            intensity: 7,
            createdAt: now.subtract(Duration(days: i)),
            updatedAt: now,
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(1.6),
              ),
              child: Scaffold(
                body: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                        child: Column(
                          children: [
                            CozyCalendar(
                              entries: entries,
                              recentEntries: entries,
                              streak: 3,
                              weeklyCount: 3,
                              weeklyIntensityTotal: 22.5,
                              hasMoodToday: true,
                              onStreak: () {},
                              now: now,
                            ),
                            const SizedBox(height: 16),
                            const JournalingCard(),
                            const SizedBox(height: 16),
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                "💛 You're doing great. Small steps count.",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 72,
                      child: Center(child: Text('Button row')),
                    ),
                  ],
                ),
                bottomNavigationBar: const SizedBox(height: 80),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Cozy Calendar'), findsOneWidget);
        expect(
          tester.getTopLeft(find.text('Journaling')).dx,
          tester.getTopLeft(find.text('Cozy Calendar')).dx,
        );
        expect(
          tester.getSize(find.byType(JournalingCard)).width,
          tester.getSize(find.byType(CozyCalendar)).width,
        );
        expect(find.text('Avg intensity 7.5'), findsOneWidget);
        expect(find.text('Recent entries'), findsOneWidget);
        expect(find.text('calm'), findsNWidgets(3));
        await tester.ensureVisible(find.text('View Log ›'));
        await tester.pumpAndSettle();
        expect(
          tester.getRect(find.text('View Log ›')).bottom,
          lessThan(size.height - 152),
        );
        await tester.ensureVisible(
          find.text("💛 You're doing great. Small steps count."),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .getRect(find.text("💛 You're doing great. Small steps count."))
              .bottom,
          lessThanOrEqualTo(size.height - 152),
        );
        expect(find.text('Start Writing'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}

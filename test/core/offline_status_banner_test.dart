import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/core/services/network_status.dart';
import 'package:cozy_health/core/theme/app_theme.dart';
import 'package:cozy_health/core/widgets/offline_status_banner.dart';

void main() {
  testWidgets(
    'Offline banner retries, hides online, and dismisses for the session',
    (tester) async {
      var retries = 0;
      networkOffline.value = false;
      addTearDown(() => networkOffline.value = null);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(body: OfflineStatusBanner(onRetry: () => retries++)),
        ),
      );
      expect(find.byIcon(Icons.cloud_off), findsNothing);
      networkOffline.value = true;
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      await tester.tap(find.byTooltip('Retry connection'));
      expect(retries, 1);
      networkOffline.value = false;
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.cloud_off), findsNothing);
      networkOffline.value = true;
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Dismiss offline banner'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.cloud_off), findsNothing);
      networkOffline.value = false;
      await tester.pumpAndSettle();
      networkOffline.value = true;
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.cloud_off), findsNothing);
    },
  );
}

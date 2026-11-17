import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/core/models/subscription_status.dart';
import 'package:cozy_health/core/theme/cozy_colors.dart';
import 'package:cozy_health/features/settings/data/store_subscription_links.dart';
import 'package:cozy_health/features/settings/presentation/widgets/store_plan_panel.dart';

SubscriptionStatus storePlan({
  String platform = 'apple',
  String state = 'active',
  bool active = true,
}) => SubscriptionStatus.fromJson({
  'id': 'owned-subscription',
  'plan': 'premium',
  'status': active ? 'active' : 'expired',
  'platform': platform,
  'store_management': {'store': 'Store'},
  'store_state': state,
  'auto_renews': state == 'active',
  'expires_at': DateTime.now()
      .add(const Duration(days: 5))
      .toUtc()
      .toIso8601String(),
});

void main() {
  test(
    'legacy and development access do not masquerade as store purchases',
    () {
      expect(
        SubscriptionStatus.fromJson({
          'plan': 'premium',
          'status': 'active',
          'platform': 'apple',
        }).isStoreManaged,
        false,
      );
      expect(
        SubscriptionStatus.fromJson({
          'plan': 'premium',
          'status': 'active',
          'source': 'development_test',
          'platform': 'apple',
          'store_management': {'store': 'Apple'},
        }).isStoreManaged,
        false,
      );
      final plan = storePlan(state: 'canceled');
      expect(plan.cancelAtPeriodEnd, true);
      expect(SubscriptionStatus.fromJson(plan.toJson()).storePlatform, 'apple');
    },
  );

  test('unknown stores and unapproved addresses cannot be opened', () async {
    expect(StoreSubscriptionLinks.manage('unknown'), isNull);
    expect(
      await StoreSubscriptionLinks.open(
        Uri.parse('https://example.test/subscriptions'),
      ),
      false,
    );
    expect(
      await StoreSubscriptionLinks.open(
        Uri.parse(
          'https://apps.apple.com/account/subscriptions?redirect=elsewhere',
        ),
      ),
      false,
    );
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'plan links follow the purchased store and fit large text in $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final opened = <Uri>[];
        var refreshed = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              brightness: brightness,
              extensions: [
                brightness == Brightness.dark
                    ? CozyColors.dark
                    : CozyColors.light,
              ],
            ),
            home: Scaffold(
              body: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                child: ListView(
                  children: [
                    StorePlanPanel(
                      subscription: storePlan(
                        platform: 'google',
                        state: 'canceled',
                      ),
                      onRefresh: () => refreshed++,
                      openLink: (uri) async {
                        opened.add(uri);
                        return true;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        expect(find.text('Automatic renewal off'), findsOneWidget);
        expect(find.text('Managed through Google Play'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Manage subscription').hitTestable(),
          180,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Manage subscription'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('View store purchase history').hitTestable(),
          180,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('View store purchase history'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Refresh plan status').hitTestable(),
          180,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Refresh plan status'));
        await tester.pumpAndSettle();
        expect(opened, [
          StoreSubscriptionLinks.manage('google'),
          StoreSubscriptionLinks.history('google'),
        ]);
        expect(refreshed, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('launch failure opens the centred recovery dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [CozyColors.light]),
        home: Scaffold(
          body: ListView(
            children: [
              StorePlanPanel(
                subscription: storePlan(),
                onRefresh: () {},
                openLink: (_) async => false,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Manage subscription'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Could not open the store'), findsOneWidget);
  });

  testWidgets('revoked access is shown as removed rather than active', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [CozyColors.light]),
        home: Scaffold(
          body: ListView(
            children: [
              StorePlanPanel(
                subscription: storePlan(state: 'revoked', active: false),
                onRefresh: () {},
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Store access removed'), findsOneWidget);
    expect(find.text('Active'), findsNothing);
  });
}

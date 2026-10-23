import '../../../../core/services/feature_flags_service.dart';
import 'package:cozy_health/features/activity/presentation/screens/activity_screens.dart';
import 'package:cozy_health/features/settings/presentation/screens/provider_hub_screen.dart';
import 'package:cozy_health/features/community/presentation/screens/community_hub_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/cozy_colors.dart';
import 'package:go_router/go_router.dart';
import '../widgets/quick_actions_sheet.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/bottom_navigation_bar.dart';
import 'home_screen.dart';
import '../widgets/feature_tour.dart';
import '../../../crisis/presentation/widgets/crisis_fab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.notificationFocus});
  final String? notificationFocus;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _tourTargets = FeatureTourTargets();
  late final List<Widget> _screens = [
    HomeScreen(
      tourTargets: _tourTargets,
      notificationFocus: widget.notificationFocus,
    ),
    const ActivityScreen(),
    const ProviderHubScreen(),
    const CommunityHubScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FeatureFlagsService.instance,
      builder: (context, _) => Scaffold(
        body: SafeArea(
          bottom: false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              SizedBox.expand(
                key: const ValueKey('main-tab-content'),
                child: _screens[_currentIndex],
              ),
              if (_currentIndex != 2 &&
                  MediaQuery.viewInsetsOf(context).bottom == 0) ...[
                Positioned(
                  right: context.cozyColors.wellness.floatingInset,
                  bottom:
                      context.cozyColors.wellness.floatingInset +
                      context.cozyColors.wellness.floatingSize +
                      context.cozyColors.wellness.floatingGap,
                  child: CrisisFab(key: _tourTargets.crisis),
                ),
                Positioned(
                  right: 16,
                  bottom: context.cozyColors.wellness.floatingInset,
                  child: Semantics(
                    button: true,
                    label: 'Open quick actions',
                    hint: 'Long press to contact your next of kin',
                    onTap: () => _showQuickActionsSheet(context),
                    onLongPress: () => context.push(AppRouter.crisisContact),
                    excludeSemantics: true,
                    child: Tooltip(
                      message: 'Open quick actions',
                      triggerMode: TooltipTriggerMode.manual,
                      child: GestureDetector(
                        onLongPress: () =>
                            context.push(AppRouter.crisisContact),
                        child: FloatingActionButton(
                          key: _tourTargets.journal,
                          heroTag: 'quick-actions',
                          shape: const CircleBorder(),
                          elevation: 2,
                          highlightElevation: 4,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          onPressed: () => _showQuickActionsSheet(context),
                          child: const Icon(Icons.add),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        bottomNavigationBar: CustomBottomNavigationBar(
          showAssistant: true,
          assistantTourKey: _tourTargets.assistant,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }

  void _showQuickActionsSheet(BuildContext context) {
    showQuickActionsSheet(
      context,
      onMood: () => context.push(AppRouter.moodFeeling),
      onJournal: () => context.push(AppRouter.journal),
      onProvider: () => setState(() => _currentIndex = 2),
      onBreathe: () => context.push(AppRouter.breathing),
    );
  }
}

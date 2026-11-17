import '../../../../core/services/feature_flags_service.dart';
import '../../../../core/widgets/app_pressable.dart';
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
                  bottom: context.cozyColors.wellness.floatingInset,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CrisisFab(key: _tourTargets.crisis),
                      SizedBox(height: context.cozyColors.wellness.floatingGap),
                      Semantics(
                        button: true,
                        label: 'Open quick actions',
                        hint: 'Long press to contact your next of kin',
                        onTap: () => _showQuickActionsSheet(context),
                        onLongPress: () =>
                            context.push(AppRouter.crisisContact),
                        excludeSemantics: true,
                        child: Tooltip(
                          message: 'Open quick actions',
                          triggerMode: TooltipTriggerMode.manual,
                          child: GestureDetector(
                            onLongPress: () =>
                                context.push(AppRouter.crisisContact),
                            child: AppPressable(
                              key: _tourTargets.journal,
                              label: 'Actions',
                              onPressed: () => _showQuickActionsSheet(context),
                              child: Container(
                                key: const ValueKey('quick-actions-control'),
                                constraints: BoxConstraints(
                                  minHeight: context.cozyColors.wellness.touch,
                                ),
                                padding: EdgeInsets.all(
                                  context.cozyColors.wellness.contentGap,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(
                                    context.cozyColors.wellness.tileRadius,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.grid_view_rounded,
                                      size: context
                                          .cozyColors
                                          .wellness
                                          .actionIcon,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                    ),
                                    SizedBox(
                                      width: context.cozyColors.wellness.small,
                                    ),
                                    Text(
                                      'Actions',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onPrimary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        bottomNavigationBar: CustomBottomNavigationBar(
          showProvider: true,
          providerTourKey: _tourTargets.provider,
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

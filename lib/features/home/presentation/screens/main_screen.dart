import '../../../../core/services/feature_flags_service.dart';
import 'package:cozy_health/features/activity/presentation/screens/activity_screens.dart';
import 'package:cozy_health/features/assistant/presentation/screens/assistant_screen.dart';
import 'package:cozy_health/features/community/presentation/screens/community_hub_screen.dart';
import 'package:cozy_health/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/mood_entry.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/bottom_navigation_bar.dart';
import 'home_screen.dart';
import '../widgets/feature_tour.dart';
import '../../../crisis/presentation/widgets/crisis_fab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _tourTargets = FeatureTourTargets();
  late final List<Widget> _screens = [
    HomeScreen(tourTargets: _tourTargets),
    const ActivityScreen(),
    const AssistantScreen(),
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
              if (MediaQuery.viewInsetsOf(context).bottom == 0) ...[
                Positioned(
                  right: 16,
                  bottom: 88,
                  child: CrisisFab(key: _tourTargets.crisis),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Semantics(
                    button: true,
                    label: 'Open quick actions',
                    child: GestureDetector(
                      onLongPress: () => context.push(AppRouter.crisisHub),
                      child: FloatingActionButton(
                        key: _tourTargets.journal,
                        heroTag: 'quick-actions',
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        onPressed: () => _showQuickActionsSheet(context),
                        child: const Icon(Icons.add),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        bottomNavigationBar: CustomBottomNavigationBar(
          showAssistant: FeatureFlags.isEnabled('ai_assistant'),
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: .32),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;

        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color:
                        Theme.of(context).dividerTheme.color ??
                        AppColors.border,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.borderStrong,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'What would you\nlike to do?',
                      style: AppTextStyles.heading2.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 18),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent:
                          96 + MediaQuery.textScalerOf(context).scale(18) * 4,
                      children: [
                        _QuickActionTile(
                          icon: MoodEntry.moodEmojis['good'] ?? '',
                          label: 'Log mood',
                          onTap: () {
                            Navigator.of(context).pop();
                            context.push(AppRouter.moodFeeling);
                          },
                        ),
                        _QuickActionTile(
                          icon: '📝',
                          label: 'Journal',
                          onTap: () {
                            Navigator.of(context).pop();
                            context.push(AppRouter.journal);
                          },
                        ),
                        if (FeatureFlags.isEnabled('ai_assistant'))
                          _QuickActionTile(
                            icon: '💬',
                            label: 'Chat',
                            onTap: () {
                              Navigator.of(context).pop();
                              setState(() => _currentIndex = 2);
                            },
                          ),
                        _QuickActionTile(
                          icon: '🌬',
                          label: 'Breathe',
                          onTap: () {
                            Navigator.of(context).pop();
                            context.push(AppRouter.breathing);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onSurface,
                          side: BorderSide(
                            color:
                                Theme.of(context).dividerTheme.color ??
                                AppColors.border,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerTheme.color ?? AppColors.border,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTextStyles.body1.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

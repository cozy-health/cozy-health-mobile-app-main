import 'package:cozy_health/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_surface.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/models/reminder_settings.dart';
import '../../data/profile_repository.dart';

class ReminderTimesScreen extends StatefulWidget {
  const ReminderTimesScreen({super.key});

  @override
  State<ReminderTimesScreen> createState() => _ReminderTimesScreenState();
}

class _ReminderTimesScreenState extends State<ReminderTimesScreen> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 20, minute: 0); // 8:00 PM
  final List<String> _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final List<bool> _selectedDays = [true, true, true, true, true, false, false];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = LocalDbService().getUserProfile();
    if (profile == null) return;
    final time = profile.dailyCheckinTime.split(':');
    _selectedTime = TimeOfDay(
      hour: int.tryParse(time.first) ?? 20,
      minute: int.tryParse(time.last) ?? 0,
    );
    final days =
        ReminderSettings.resolve(profile.reminderSettings)['mood_days'] as List;
    for (var i = 0; i < 7; i++) {
      _selectedDays[i] = days.contains(i + 1);
    }
  }

  Future<void> _saveReminder() async {
    final profile = LocalDbService().getUserProfile();
    if (_saving || profile == null) return;
    setState(() => _saving = true);
    try {
      await ProfileRepository().saveProfile(
        profile
            .copyWithField(
              'daily_checkin_time',
              '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
            )
            .copyWithField('reminder_settings', {
              ...ReminderSettings.resolve(profile.reminderSettings),
              'mood_days': [
                for (var i = 0; i < 7; i++)
                  if (_selectedDays[i]) i + 1,
              ],
            })
            .copyWith(updatedAt: DateTime.now()),
      );
      if (!mounted) return;
      final formattedTime = _selectedTime.format(context);
      AppSnackbar.show(
        context,
        AppSnackbar.info(
          'Reminder saved for $formattedTime. Changes will sync when connected.',
        ),
      );
      context.pop();
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(
          context,
          AppSnackbar.error('Could not save reminder. Please try again.'),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Reminder time',
                      style: AppTextStyles.heading1.copyWith(
                        fontSize: 28,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'When would you like Cozy Health to gently remind you to check in?',
                      style: AppTextStyles.body1.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                    SizedBox(height: 48),

                    // Native-like Time Picker Button
                    Center(
                      child: Semantics(
                        button: true,
                        label:
                            'Select time, current is ${_selectedTime.format(context)}',
                        child: InkWell(
                          onTap: () async {
                            final TimeOfDay? time = await showTimePicker(
                              context: context,
                              initialTime: _selectedTime,
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: Theme.of(context).colorScheme,
                                    textButtonTheme: TextButtonThemeData(
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors
                                            .primary, // button text color
                                      ),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (time != null) {
                              setState(() {
                                _selectedTime = time;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: AppSurface.border(context),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      _selectedTime.format(context),
                                      style: AppTextStyles.heading1.copyWith(
                                        fontSize: 48,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Icon(
                                  Icons.edit,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 64),
                    Text(
                      'Repeat on',
                      style: AppTextStyles.body2.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_days.length, (index) {
                        final isSelected = _selectedDays[index];
                        return Semantics(
                          button: true,
                          label: 'Toggle ${_days[index]}',
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedDays[index] = !_selectedDays[index];
                              });
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.surface,
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.outline,
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _days[index],
                                  style: AppTextStyles.body1.copyWith(
                                    color: isSelected
                                        ? AppColors.white
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 48),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: AppButton(
                text: 'Save',
                isLoading: _saving,
                onPressed: _saving ? null : _saveReminder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

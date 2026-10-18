import 'package:cozy_health/core/theme/app_surface.dart';
import 'package:cozy_health/core/widgets/app_snackbar.dart';
import '../../../../core/security_gate.dart';
import '../../../../core/services/security_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/local_db_service.dart';
import '../../data/profile_repository.dart';
import '../widgets/marketing_consent_toggle.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _appLock = false;
  bool _journalPin = false;
  bool _securityBusy = false;
  bool _securityReady = false;
  bool _showUsername = true;
  bool _showStats = true;
  bool _referenceMood = true;
  bool _referenceJournal = false;
  bool _improveAi = false;
  bool _shareAnalytics = false;
  bool _shareCrashReports = false;
  final _owner = LocalDbService().activeUserId;
  Future<void> _loadPrivacy() async {
    final box = await LocalDbService().settingsBox();
    final value = box.get('privacy_preferences');
    if (!mounted || _owner != LocalDbService().activeUserId || value is! Map) {
      return;
    }
    setState(() {
      _referenceMood = value['reference_mood'] == true;
      _referenceJournal = value['reference_journal'] == true;
      _improveAi = value['improve_ai'] == true;
      _shareAnalytics = value['analytics'] == true;
      _shareCrashReports = value['crash_reports'] == true;
    });
  }

  Future<void> _savePrivacy() async {
    final box = await LocalDbService().settingsBox();
    if (_owner != LocalDbService().activeUserId) return;
    await box.put('privacy_preferences', {
      'reference_mood': _referenceMood,
      'reference_journal': _referenceJournal,
      'improve_ai': _improveAi,
      'analytics': _shareAnalytics,
      'crash_reports': _shareCrashReports,
    });
    final assistant = box.get('assistant_preferences');
    await box.put('assistant_preferences', {
      ...(assistant is Map ? assistant : {}),
      'reference_mood': _referenceMood,
      'reference_journal': _referenceJournal,
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPrivacy();
    _loadSecurity();
    final profile = LocalDbService().getUserProfile();
    if (profile != null) {
      _showUsername = profile.showUsername;
      _showStats = profile.showStats;
    }
  }

  Future<void> _loadSecurity() async {
    try {
      final lock = await SecurityService.instance.appLockEnabled();
      final pin = await SecurityService.instance.hasPin();
      if (mounted) {
        setState(() {
          _appLock = lock;
          _journalPin = pin;
          _securityReady = true;
        });
      }
    } catch (_) {
      _showSecurityError();
    }
  }

  void _showSecurityError() {
    if (!mounted) return;
    AppSnackbar.show(
      context,
      AppSnackbar.fromLegacy(
        content: Text('Unable to update security settings. Try again.'),
      ),
    );
  }

  Future<void> _toggleLock(bool value) async {
    if (_securityBusy || !_securityReady) return;
    setState(() => _securityBusy = true);
    try {
      if (!await SecurityService.instance.authenticate()) {
        if (mounted) {
          AppSnackbar.show(
            context,
            AppSnackbar.fromLegacy(
              content: Text(
                'Biometric verification is required. Set up Face ID or fingerprint in device settings.',
              ),
            ),
          );
        }
        return;
      }
      await SecurityService.instance.setAppLock(value);
      await _loadSecurity();
    } catch (_) {
      _showSecurityError();
    } finally {
      if (mounted) setState(() => _securityBusy = false);
    }
  }

  Future<void> _togglePin(bool value) async {
    if (_securityBusy || !_securityReady) return;
    setState(() => _securityBusy = true);
    try {
      await journalPinDialog(context, setup: value);
      await _loadSecurity();
    } catch (_) {
      _showSecurityError();
    } finally {
      if (mounted) setState(() => _securityBusy = false);
    }
  }

  void _updateShowUsername(bool value) {
    setState(() => _showUsername = value);
    ProfileRepository().updateField('showUsername', value);
  }

  void _updateShowStats(bool value) {
    setState(() => _showStats = value);
    ProfileRepository().updateField('showStats', value);
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
        ),
        title: Text(
          'Privacy',
          style: AppTextStyles.heading2.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 24),

              _SettingsSection(
                title: 'Provider access',
                children: [
                  ListTile(
                    title: const Text('Provider Access Log'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(AppRouter.providerAccessLog),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              _SettingsSection(
                title: 'Security',
                children: [
                  _SettingsToggleRow(
                    label: 'App lock — Face ID / biometrics',
                    value: _appLock,
                    onChanged: _toggleLock,
                  ),
                  _SettingsToggleRow(
                    label: 'Journal PIN (4–6 digits)',
                    value: _journalPin,
                    onChanged: _togglePin,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const MarketingConsentToggle(),
              const SizedBox(height: 32),
              _SettingsSection(
                title: 'Profile visibility',
                children: [
                  _SettingsToggleRow(
                    label: 'Show my username',
                    value: _showUsername,
                    onChanged: _updateShowUsername,
                  ),
                  _SettingsToggleRow(
                    label: 'Show my stats',
                    value: _showStats,
                    onChanged: _updateShowStats,
                  ),
                ],
              ),
              SizedBox(height: 32),

              _SettingsSection(
                title: 'AI & Data',
                children: [
                  _SettingsToggleRow(
                    label: 'Let Cozy reference my mood logs',
                    value: _referenceMood,
                    onChanged: (v) {
                      setState(() => _referenceMood = v);
                      _savePrivacy();
                    },
                  ),
                  _SettingsToggleRow(
                    label: 'Let Cozy reference my journal',
                    value: _referenceJournal,
                    onChanged: (v) {
                      setState(() => _referenceJournal = v);
                      _savePrivacy();
                    },
                  ),
                  _SettingsToggleRow(
                    label: 'Future preference: improve AI with my conversations',
                    value: _improveAi,
                    onChanged: (v) {
                      setState(() => _improveAi = v);
                      _savePrivacy();
                    },
                  ),
                ],
              ),
              SizedBox(height: 32),

              _SettingsSection(
                title: 'Analytics',
                children: [
                  _SettingsToggleRow(
                    label: 'Share anonymous usage data',
                    value: _shareAnalytics,
                    onChanged: (v) {
                      setState(() => _shareAnalytics = v);
                      _savePrivacy();
                    },
                  ),
                  _SettingsToggleRow(
                    label: 'Share crash reports',
                    value: _shareCrashReports,
                    onChanged: (v) {
                      setState(() => _shareCrashReports = v);
                      _savePrivacy();
                    },
                  ),
                ],
              ),
              SizedBox(height: 32),

              _SettingsSection(
                title: 'Blocked users',
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.push(AppRouter.blockedUsers),
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Manage blocked users',
                                style: AppTextStyles.body1.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 20,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.textSubtleDark
                                  : AppColors.textSubtleLight,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: AppTextStyles.body1.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        Material(
          color: Theme.of(context).colorScheme.surface,
          shape: AppSurface.shape(context, BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: List.generate(children.length, (index) {
              final isLast = index == children.length - 1;
              return Column(
                children: [
                  children[index],
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.4),
                      ),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.body1.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              CupertinoSwitch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

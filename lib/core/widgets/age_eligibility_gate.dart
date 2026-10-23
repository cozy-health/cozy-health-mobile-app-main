import 'dart:async';
import 'package:flutter/material.dart';
import '../routing/app_router.dart';
import '../services/age_eligibility_service.dart';
import '../services/feature_flags_service.dart';
import '../services/guest_session_service.dart';
import '../services/consent_service.dart';
import '../services/legal_documents.dart';
import '../services/network_status.dart';
import '../storage/token_storage.dart';
import '../../features/auth/data/auth_service.dart';
import 'age_details_fields.dart';

class AgeEligibilityGate extends StatefulWidget {
  const AgeEligibilityGate({
    super.key,
    required this.child,
    this.review = false,
  });
  final bool review;
  final Widget child;
  @override
  State<AgeEligibilityGate> createState() => _AgeEligibilityGateState();
}

class _AgeEligibilityGateState extends State<AgeEligibilityGate>
    with WidgetsBindingObserver {
  final service = AgeEligibilityService.instance;
  final dob = TextEditingController(), country = TextEditingController();
  final name = TextEditingController(),
      email = TextEditingController(),
      note = TextEditingController();
  StreamSubscription<void>? _sessions;
  Timer? _timer;
  bool _authenticated = false,
      _guest = false,
      _busy = false,
      _sessionKnown = false;
  String? _error;
  String _relationship = 'parent', _caseKind = 'dob_correction';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppRouter.router.routeInformationProvider.addListener(_route);
    FeatureFlagsService.instance.addListener(_changed);
    service.addListener(_changed);
    networkOffline.addListener(_network);
    _sessions = TokenStorage.sessionChanges.listen((_) {
      service.invalidate();
      _refresh();
    });
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (service.enabled) _refresh();
    });
    _refresh();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _route() {
    _changed();
    if (service.enabled) _refresh();
  }

  void _network() {
    if (networkOffline.value == true &&
        service.current?.onlineRequired != false) {
      service.invalidate();
    }
    _changed();
  }

  Future<void> _refresh() async {
    final generation = TokenStorage.generation;
    final authenticated = await TokenStorage().getToken() != null;
    final guest = await GuestSessionService().isGuestSession();
    if (authenticated && (service.enabled || widget.review)) {
      await service.refresh();
    }
    if (!mounted || generation != TokenStorage.generation) return;
    setState(() {
      _authenticated = authenticated;
      _guest = guest;
      _sessionKnown = true;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    } else if (service.current?.onlineRequired != false) {
      service.invalidate();
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'We could not save this step. Check the details and your connection, then retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool get _publicRoute {
    final path = AppRouter.router.routeInformationProvider.value.uri.path;
    return {
      AppRouter.ageAuthorization,
      AppRouter.splash,
      AppRouter.onboarding,
      AppRouter.welcome,
      AppRouter.login,
      AppRouter.createAccount,
      AppRouter.forgotPassword,
      AppRouter.crisisHub,
      AppRouter.grounding,
      AppRouter.breathing,
      AppRouter.professionalHelp,
      AppRouter.crisisFollowUp,
      AppRouter.safetyPlanView,
      AppRouter.accountDeletion,
      AppRouter.helpSupport,
      AppRouter.reportProblem,
      AppRouter.feedback,
      AppRouter.legalHub,
      AppRouter.termsPolicies,
      AppRouter.about,
      AppRouter.emailSettings,
    }.contains(path);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.review && (!service.enabled || _publicRoute)) {
      return widget.child;
    }
    if (!_sessionKnown) {
      return const Scaffold(
        body: SafeArea(child: Center(child: Text('Checking account access…'))),
      );
    }
    if (!widget.review && _authenticated && !service.blocked) {
      return widget.child;
    }
    final state = service.current;
    // The existing consent gate collects the patient's own current consent.
    if (!widget.review &&
        state?.reason == 'consent_required' &&
        state?.data['patient_consent_ready'] == true &&
        networkOffline.value == false) {
      return widget.child;
    }
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Your age. Your privacy.',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    (_guest || !_authenticated)
                        ? 'Sign in and complete age requirements before saving private information.'
                        : !service.enabled
                        ? 'Age and guardian safeguards are being prepared. Invitations remain unavailable until the required policies and safeguards are approved.'
                        : switch (state?.reason) {
                            'age_required' =>
                              'Tell us your date of birth and country before using private features.',
                            'under_age' =>
                              'Cozy Health accounts are for ages 13 and older. Contact the team for help with an existing account.',
                            'country_not_enabled' =>
                              'Private features for young people are not available in your country yet. Your records have been kept securely.',
                            'guardian_required' =>
                              'A parent or legal guardian needs to authorize participation. This does not give them access to your private records.',
                            'age_disputed' =>
                              'The Cozy Health team needs to resolve your age or guardian case before private features can open.',
                            'consent_required' =>
                              'The required policies are not available for acceptance yet. Private features remain restricted.',
                            null when state?.allowed == true =>
                              'Your current eligibility checks are complete. You can manage authorization, update your residence or ask the team for a correction below.',
                            _ =>
                              'Connect to the internet to check access. Young people need an online check before opening private features.',
                          },
                  ),
                  const SizedBox(height: 24),
                  if (widget.review)
                    TextButton(
                      onPressed: () => AppRouter.router.go(AppRouter.settings),
                      child: const Text('Back to settings'),
                    ),
                  if (_error != null) Text(_error!, semanticsLabel: _error),
                  if (state?.data['date_of_birth'] != null)
                    Text(
                      'Date of birth: ${state!.data['date_of_birth']}. To correct this, contact the team below.',
                    ),
                  if (_authenticated && state?.reason != 'age_required')
                    ExpansionTile(
                      title: const Text('Country of residence'),
                      children: [
                        Text(
                          'Current country: ${state?.data['residence_country'] ?? 'Not supplied'}. A change ends existing guardian authorization and rechecks access.',
                        ),
                        ResidenceCountryField(
                          country: country,
                          enabled: !_busy,
                          onChanged: _changed,
                        ),
                        TextButton(
                          onPressed: _busy || country.text.length != 2
                              ? null
                              : () => _run(
                                  () => service.updateResidence(country.text),
                                ),
                          child: const Text('Save new residence'),
                        ),
                      ],
                    ),
                  for (final item
                      in (state?.data['cases'] as List? ?? const []))
                    if (item is Map)
                      ListTile(
                        title: Text('Team request: ${item['status']}'),
                        subtitle: Text(
                          item['resolution']?.toString() ??
                              'Waiting for a team response. No response time is guaranteed.',
                        ),
                      ),
                  if (_authenticated &&
                      (state?.reason == 'age_required' ||
                          state?.band == 'unknown')) ...[
                    AgeDetailsFields(
                      dob: dob,
                      country: country,
                      onChanged: _changed,
                      enabled: !_busy,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed:
                          _busy ||
                              dob.text.isEmpty ||
                              country.text.trim().length != 2
                          ? null
                          : () => _run(
                              () => service.submit('/me/age', {
                                'date_of_birth': dob.text,
                                'residence_country': country.text
                                    .trim()
                                    .toUpperCase(),
                              }),
                            ),
                      child: const Text('Save age details'),
                    ),
                  ],
                  if (_authenticated && state?.band == 'minor') ...[
                    Text(
                      'Guardian authorization',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state?.data['invitations_enabled'] == true
                          ? 'First verify your own email, then invite your parent or legal guardian.'
                          : 'Guardian invitations are not available yet. No authorization is granted by entering an email.',
                    ),
                    if (state?.data['invitations_enabled'] == true &&
                        state?.reason != 'age_disputed') ...[
                      TextField(
                        controller: name,
                        decoration: const InputDecoration(
                          labelText: 'Guardian name',
                        ),
                        maxLength: 120,
                      ),
                      TextField(
                        controller: email,
                        decoration: const InputDecoration(
                          labelText: 'Guardian email',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        maxLength: 190,
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: _relationship,
                        decoration: const InputDecoration(
                          labelText: 'Relationship',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'parent',
                            child: Text('Parent'),
                          ),
                          DropdownMenuItem(
                            value: 'legal_guardian',
                            child: Text('Legal guardian'),
                          ),
                        ],
                        onChanged: _busy
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() => _relationship = value);
                                }
                              },
                      ),
                      FilledButton(
                        onPressed:
                            _busy || state?.data['email_verified'] != true
                            ? null
                            : () => _run(
                                () => service.submit('/me/guardian', {
                                  'guardian_name': name.text.trim(),
                                  'guardian_email': email.text.trim(),
                                  'relationship': _relationship,
                                }),
                              ),
                        child: const Text('Send / resend guardian invitation'),
                      ),
                    ],
                    if (state?.data['authorization'] is Map)
                      Text(
                        'Request status: ${(state!.data['authorization'] as Map)['status']}',
                      ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _run(service.cancelGuardian),
                      child: const Text(
                        'Cancel guardian request / withdraw authorization',
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          AppRouter.router.push(AppRouter.emailSettings),
                      child: const Text('Verify my email'),
                    ),
                  ],
                  FilledButton.tonal(
                    onPressed: _busy ? null : _refresh,
                    child: const Text('Check access again'),
                  ),
                  if (_authenticated)
                    ExpansionTile(
                      title: const Text('Ask the Cozy Health team for help'),
                      children: [
                        const Text(
                          'Use this for a wrong birthday, disputed guardian, appeal or privacy request. Do not include identity documents or private journal content. Age/guardian disputes pause private access while reviewed.',
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: _caseKind,
                          items: const [
                            DropdownMenuItem(
                              value: 'dob_correction',
                              child: Text('Wrong date of birth'),
                            ),
                            DropdownMenuItem(
                              value: 'guardian_dispute',
                              child: Text('Guardian dispute'),
                            ),
                            DropdownMenuItem(
                              value: 'appeal',
                              child: Text('Appeal'),
                            ),
                            DropdownMenuItem(
                              value: 'privacy',
                              child: Text('Privacy request'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _caseKind = value);
                            }
                          },
                        ),
                        TextField(
                          controller: note,
                          maxLength: 2000,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Explain the request',
                          ),
                        ),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => _run(() async {
                                  await service.submit('/me/age-support', {
                                    'kind': _caseKind,
                                    'message': note.text.trim(),
                                  });
                                  if (!context.mounted) return;
                                  note.clear();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Your request is in the team queue.',
                                      ),
                                    ),
                                  );
                                }),
                          child: const Text('Send to the team'),
                        ),
                      ],
                    ),
                  TextButton(
                    onPressed: () => AppRouter.router.push(AppRouter.crisisHub),
                    child: const Text(
                      'Emergency support and calming exercises',
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        LegalDocuments.open('https://cozyhealth.org/guardians'),
                    child: const Text('Young people and guardian notice'),
                  ),
                  if (_authenticated) ...[
                    if (service.enabled)
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => _run(() async {
                                final consents = ConsentService();
                                final current = await consents.load();
                                if (current == null) {
                                  throw StateError('Sign in again.');
                                }
                                await consents.withdrawHealth(current);
                                await service.refresh();
                              }),
                        child: const Text('Withdraw my health-data consent'),
                      ),
                    TextButton(
                      onPressed: () =>
                          AppRouter.router.push(AppRouter.accountDeletion),
                      child: const Text('Delete my account'),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                              await AuthService().logout();
                              AppRouter.router.go(AppRouter.welcome);
                            }),
                      child: const Text('Log out'),
                    ),
                  ] else
                    TextButton(
                      onPressed: () => AppRouter.router.go(AppRouter.login),
                      child: const Text('Sign in'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sessions?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    AppRouter.router.routeInformationProvider.removeListener(_route);
    FeatureFlagsService.instance.removeListener(_changed);
    service.removeListener(_changed);
    networkOffline.removeListener(_network);
    for (final controller in [dob, country, name, email, note]) {
      controller.dispose();
    }
    super.dispose();
  }
}

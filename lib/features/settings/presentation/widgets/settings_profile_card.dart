import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/user_profile.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/guest_session_service.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/theme/app_surface.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../data/profile_repository.dart';

/// Owns the profile card's loading and recovery state independently of Settings.
class SettingsProfileCard extends StatefulWidget {
  const SettingsProfileCard({
    super.key,
    this.repository,
    this.isGuestSession,
    this.cachedProfile,
  });

  final ProfileRepository? repository;
  final Future<bool> Function()? isGuestSession;
  final UserProfile? Function()? cachedProfile;

  @override
  State<SettingsProfileCard> createState() => _SettingsProfileCardState();
}

class _SettingsProfileCardState extends State<SettingsProfileCard> {
  late final ProfileRepository _repository;
  late Stream<UserProfile?> _profiles;
  late Future<bool> _guest;
  StreamSubscription<void>? _accounts, _sessions;
  Timer? _deadline;
  UserProfile? _recovered;
  int _generation = 0, _request = 0;
  bool _retrying = false, _timedOut = false, _retryFailed = false;

  UserProfile? _cached() {
    try {
      return widget.cachedProfile?.call() ??
          (widget.cachedProfile == null
              ? LocalDbService.instance.getUserProfile()
              : null);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ProfileRepository();
    _reset();
    _accounts = LocalDbService.instance.accountChanges.listen(
      (_) => _changed(),
    );
    _sessions = TokenStorage.sessionChanges.listen((_) => _changed());
  }

  void _reset() {
    _generation++;
    _request++;
    _recovered = null;
    _retrying = _timedOut = _retryFailed = false;
    _profiles = _repository.watchProfile();
    _guest =
        widget.isGuestSession?.call() ?? GuestSessionService().isGuestSession();
    _deadline?.cancel();
    final generation = _generation;
    _deadline = Timer(const Duration(seconds: 8), () {
      if (!mounted || generation != _generation) return;
      setState(() {
        _request++;
        _timedOut = true;
        _retrying = false;
      });
    });
  }

  void _changed() {
    if (mounted) setState(_reset);
  }

  Future<void> _retry() async {
    if (_retrying) return;
    final owner = LocalDbService.instance.activeUserId;
    final session = TokenStorage.generation;
    setState(() {
      _reset();
      _retrying = true;
    });
    final request = _request;
    try {
      final profile = await _repository.fetchProfile();
      if (!mounted ||
          request != _request ||
          owner != LocalDbService.instance.activeUserId ||
          session != TokenStorage.generation) {
        return;
      }
      setState(() {
        _recovered = profile;
        _retryFailed = profile == null;
        _retrying = false;
      });
    } catch (_) {
      if (mounted &&
          request == _request &&
          owner == LocalDbService.instance.activeUserId &&
          session == TokenStorage.generation) {
        setState(() {
          _retryFailed = true;
          _retrying = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _deadline?.cancel();
    unawaited(_accounts?.cancel());
    unawaited(_sessions?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    key: ValueKey(_generation),
    future: _guest,
    builder: (context, guest) => StreamBuilder<UserProfile?>(
      stream: _profiles,
      initialData: _cached(),
      builder: (context, snapshot) {
        final profile = snapshot.data ?? _recovered ?? _cached();
        final isGuest = guest.data == true;
        final failed = snapshot.hasError || guest.hasError || _retryFailed;
        final waiting =
            !_timedOut &&
            !failed &&
            (_retrying ||
                guest.connectionState == ConnectionState.waiting ||
                snapshot.connectionState == ConnectionState.waiting);
        return Material(
          color: Theme.of(context).colorScheme.surface,
          shape: AppSurface.shape(context, BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: isGuest || profile != null
              ? _identity(
                  context,
                  profile,
                  isGuest,
                  guest.hasData,
                  failed && !isGuest,
                )
              : waiting
              ? Semantics(
                  label: 'Loading profile',
                  liveRegion: true,
                  child: const ExcludeSemantics(
                    child: Padding(
                      key: ValueKey('settings-profile-loading'),
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          SkeletonLoader(width: 48, height: 48, radius: 24),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SkeletonLoader(
                                  width: 140,
                                  height: 18,
                                  radius: 6,
                                ),
                                SizedBox(height: 10),
                                SkeletonLoader(height: 12, radius: 4),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Padding(
                  key: const ValueKey('settings-profile-unavailable'),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile unavailable',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Your profile could not be loaded. Your other settings are still available.',
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _retrying ? null : _retry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry profile'),
                      ),
                    ],
                  ),
                ),
        );
      },
    ),
  );

  Widget _identity(
    BuildContext context,
    UserProfile? profile,
    bool guest,
    bool guestReady,
    bool failed,
  ) => InkWell(
    onTap: guestReady
        ? () => context.push(
            guest ? AppRouter.createAccount : AppRouter.profileView,
          )
        : null,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileAvatar(profile: guest ? null : profile, size: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guest ? 'Guest' : profile!.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      guest
                          ? 'Create an account to sync your data'
                          : profile!.email,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
          if (failed) ...[
            const SizedBox(height: 12),
            const Text('Could not refresh. Your saved profile is shown.'),
            TextButton(
              onPressed: _retrying ? null : _retry,
              child: Text(_retrying ? 'Refreshing…' : 'Retry profile'),
            ),
          ],
        ],
      ),
    ),
  );
}

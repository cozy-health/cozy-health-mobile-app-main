import '../../../../core/widgets/wellness_sheet.dart';
import '../../../../core/widgets/wellness_panel.dart';
import 'dart:async';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/api/api_exceptions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../data/avatar_repository.dart';
import '../../services/avatar_photo_picker.dart';

class AvatarPickerSheet extends StatefulWidget {
  const AvatarPickerSheet({
    super.key,
    this.repository,
    this.picker,
    this.isGuest = false,
    this.onCreateAccount,
    this.initialProfile,
    this.accountScope,
    this.guestLookup,
  });
  final AvatarRepository? repository;
  final AvatarPhotoPicker? picker;
  final bool isGuest;
  final UserProfile? initialProfile;
  final String? accountScope;
  final Future<bool> Function()? guestLookup;
  final VoidCallback? onCreateAccount;

  @override
  State<AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<AvatarPickerSheet> {
  late final _repository = widget.repository ?? AvatarRepository();
  late final _picker = widget.picker ?? AvatarPhotoPicker();
  late final _scope =
      widget.accountScope ??
      LocalDbService().boxName(LocalDbService.userSettingsBoxName);
  bool _busy = false, _grid = false, _permissionError = false;
  String? _preset, _error, _recovered;
  Uint8List? _photo;
  UserProfile? _profile;
  bool? _guest;
  bool _checkingSession = false;
  bool _sessionFailed = false;
  StreamSubscription<void>? _accountSubscription;
  Route<dynamic>? _confirmationRoute;
  final _scrollController = ScrollController();
  bool get _canSave => _guest == false && !_checkingSession && !_sessionFailed;
  bool get _active =>
      mounted &&
      _scope == LocalDbService().boxName(LocalDbService.userSettingsBoxName);

  @override
  void initState() {
    super.initState();
    final scope = _scope;
    _profile = widget.initialProfile;
    if (_profile == null) {
      try {
        _profile = _repository.profile;
      } catch (_) {
        /* Browsing stays available. */
      }
    }
    _guest = widget.guestLookup == null ? widget.isGuest : null;
    if (widget.guestLookup != null) _checkSession();
    _accountSubscription = LocalDbService().accountChanges.listen((_) {
      if (mounted &&
          scope !=
              LocalDbService().boxName(LocalDbService.userSettingsBoxName)) {
        final route = ModalRoute.of(context);
        final confirmation = _confirmationRoute;
        if (confirmation != null && confirmation.isActive) {
          Navigator.of(context).removeRoute(confirmation);
        }
        if (route != null && route.isActive) {
          Navigator.of(context).removeRoute(route);
        }
      }
    });
    _recover();
  }

  @override
  void dispose() {
    _accountSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _changeView(VoidCallback update) {
    setState(update);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  Future<void> _checkSession() async {
    if (_checkingSession) return;
    setState(() {
      _checkingSession = true;
      _sessionFailed = false;
      _guest = null;
    });
    try {
      final guest = await widget.guestLookup!().timeout(
        const Duration(seconds: 5),
      );
      if (_active) setState(() => _guest = guest);
    } catch (error, stack) {
      unawaited(Sentry.captureException(error, stackTrace: stack));
      if (_active) setState(() => _sessionFailed = true);
    } finally {
      if (mounted) setState(() => _checkingSession = false);
    }
  }

  Future<void> _recover() async {
    try {
      final path = await _picker.recover();
      if (_active) setState(() => _recovered = path);
    } catch (_) {
      /* A failed recovery does not change the profile. */
    }
  }

  Future<void> _pick(bool camera, {String? recovered}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _permissionError = false;
    });
    try {
      final bytes = recovered == null
          ? await _picker.pick(context, camera: camera)
          : await _picker.crop(context, recovered);
      if (!mounted || !_active) return;
      if (bytes != null) {
        if (bytes.length > 5 * 1024 * 1024) {
          throw const FormatException('Image too large');
        }
        _changeView(() {
          _photo = bytes;
          _preset = null;
          _grid = false;
          _recovered = null;
        });
      }
    } on PlatformException catch (error) {
      if (_active) {
        setState(() {
          _permissionError =
              error.code.toLowerCase().contains('access') ||
              error.code.toLowerCase().contains('denied');
          _error = _permissionError
              ? 'Camera or photo access was denied. You can allow access in your device settings.'
              : 'Could not open the camera or photo editor. Please try again.';
        });
      }
    } catch (_) {
      if (_active) {
        setState(
          () => _error =
              'Could not read this photo. Choose another JPEG or PNG image smaller than 5 MB.',
        );
      }
    } finally {
      if (_active) setState(() => _busy = false);
    }
  }

  Future<void> _save({bool remove = false}) async {
    if (_busy || !_active || !_canSave) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _repository.save(presetId: _preset, photo: _photo, remove: remove);
      if (!mounted || !_active) return;
      Navigator.pop(context);
    } catch (error, stack) {
      unawaited(Sentry.captureException(error, stackTrace: stack));
      if (_active) {
        setState(() => _error = _saveError(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _saveError(Object error) {
    if (error is ApiAuthException) {
      return 'Please sign in again before saving your picture.';
    }
    if (error is ApiException && error.statusCode == 409) {
      return 'Your account changed. Reopen your profile to try again.';
    }
    if (error is ApiValidationException || error is FormatException) {
      return 'This picture could not be saved. Choose an available avatar or a JPEG or PNG smaller than 5 MB.';
    }
    if (error is ApiServerException) {
      return 'Picture storage is temporarily unavailable. Please try again.';
    }
    if (error is StateError) {
      return 'Could not save your picture. Your profile is not ready. Reopen your profile and try again.';
    }
    return 'Could not save your picture. Check your connection and try again. Your current picture is unchanged.';
  }

  Future<void> _remove() async {
    final confirmed = await confirmWellnessAction(
      context,
      title: 'Remove profile picture?',
      message: 'Your profile will use the default picture.',
      action: 'Remove',
      onRoute: (route) => _confirmationRoute = route,
    );
    _confirmationRoute = null;
    if (confirmed == true && _active) await _save(remove: true);
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preset != null || _photo != null;
    return WellnessSheet(
      title: 'Profile photo',
      busy: _busy,
      controller: _scrollController,
      children: [
        if (_checkingSession) const Text('Checking your account…'),
        if (_sessionFailed) ...[
          const Text(
            'Could not check your account. You can browse avatars and retry before saving.',
          ),
          WellnessAction(
            onPressed: _checkSession,
            label: 'Retry account check',
          ),
        ],
        if (_guest == true) ...[
          const Text(
            'Create an account to save a profile picture. You can browse our built-in avatars here.',
          ),
          WellnessAction(
            onPressed: widget.onCreateAccount,
            label: 'Create account',
          ),
        ],
        if (_busy)
          const LinearProgressIndicator(
            semanticsLabel: 'Updating profile picture',
          ),
        if (preview) ...[
          const SizedBox(height: 20),
          Center(
            child: _photo != null
                ? ClipOval(
                    child: Image.memory(
                      _photo!,
                      width: 144,
                      height: 144,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stack) =>
                          const Icon(Icons.broken_image_outlined, size: 64),
                    ),
                  )
                : ProfileAvatar(
                    url: 'asset:$_preset',
                    size: 144,
                    label: 'Selected avatar',
                  ),
          ),
          const SizedBox(height: 20),
          WellnessAction(
            filled: true,
            onPressed: _busy || !_canSave ? null : () => _save(),
            label: 'Save picture',
          ),
          WellnessAction(
            onPressed: _busy
                ? null
                : () => _changeView(() {
                    _preset = null;
                    _photo = null;
                    _error = null;
                  }),
            label: 'Cancel selection',
          ),
        ],
        if (!preview && !_grid) ...[
          WellnessSheetOption(
            icon: Icons.face_outlined,
            label: 'Choose a built-in avatar',
            subtitle: '24 Open Peeps avatars · available offline',
            onPressed: _busy ? null : () => _changeView(() => _grid = true),
          ),
          WellnessSheetOption(
            icon: Icons.photo_library_outlined,
            label: 'Choose from gallery',
            onPressed: _busy ? null : () => _pick(false),
          ),
          WellnessSheetOption(
            icon: Icons.photo_camera_outlined,
            label: 'Take a photo',
            onPressed: _busy ? null : () => _pick(true),
          ),
          if (_profile?.avatarUrl?.isNotEmpty == true && _canSave)
            WellnessSheetOption(
              icon: Icons.delete_outline,
              destructive: true,
              label: 'Remove photo',
              onPressed: _busy ? null : _remove,
            ),
          if (_recovered != null)
            WellnessAction(
              onPressed: _busy
                  ? null
                  : () => _pick(false, recovered: _recovered),
              label: 'Recover selected photo',
            ),
        ],
        if (_grid) ...[
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AvatarRepository.presetIds.asMap().entries.map((entry) {
                final selected =
                    _preset == entry.value ||
                    (_preset == null &&
                        _profile?.avatarUrl == 'asset:${entry.value}');
                final size = ((constraints.maxWidth - 24) / 3).clamp(
                  48.0,
                  100.0,
                );
                return Semantics(
                  button: true,
                  selected: selected,
                  label: 'Open Peeps avatar ${entry.key + 1}',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(size),
                    onTap: _busy
                        ? null
                        : () => _changeView(() {
                            _preset = entry.value;
                            _grid = false;
                            _photo = null;
                            _error = null;
                          }),
                    child: Container(
                      width: size,
                      height: size,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                          width: selected ? 3 : 1,
                        ),
                      ),
                      child: ExcludeSemantics(
                        child: ProfileAvatar(
                          url: 'asset:${entry.value}',
                          size: size - 8,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          WellnessAction(
            onPressed: _busy
                ? null
                : () => _changeView(() {
                    _grid = false;
                    _preset = null;
                  }),
            label: 'Back to photo options',
          ),
        ],
        if (_error != null) Semantics(liveRegion: true, child: Text(_error!)),
        if (_permissionError)
          WellnessAction(
            onPressed: () => openAppSettings(),
            label: 'Open device settings',
          ),
      ],
    );
  }
}

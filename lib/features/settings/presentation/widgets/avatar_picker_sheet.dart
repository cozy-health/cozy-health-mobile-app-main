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
  });
  final AvatarRepository? repository;
  final AvatarPhotoPicker? picker;
  final bool isGuest;
  final VoidCallback? onCreateAccount;

  @override
  State<AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<AvatarPickerSheet> {
  late final _repository = widget.repository ?? AvatarRepository();
  late final _picker = widget.picker ?? AvatarPhotoPicker();
  late final _scope = LocalDbService().boxName(
    LocalDbService.userSettingsBoxName,
  );
  bool _busy = false, _grid = false, _permissionError = false;
  String? _preset, _error, _recovered;
  Uint8List? _photo;
  bool get _active =>
      mounted &&
      _scope == LocalDbService().boxName(LocalDbService.userSettingsBoxName);

  @override
  void initState() {
    super.initState();
    _recover();
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
        setState(() {
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
    if (_busy || !_active || widget.isGuest) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _repository.save(presetId: _preset, photo: _photo, remove: remove);
      if (!mounted || !_active) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (_active) {
        setState(
          () => _error =
              'Could not save your picture. Check your connection and try again. Your current picture is unchanged.',
        );
      }
    } finally {
      if (_active) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text('Remove profile picture?'),
        content: const Text('Your profile will use the default picture.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && _active) await _save(remove: true);
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preset != null || _photo != null;
    return PopScope(
      canPop: !_busy,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .85,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Change profile picture',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: _busy ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  if (widget.isGuest) ...[
                    const Text(
                      'Create an account to save a profile picture. You can browse our built-in avatars here.',
                    ),
                    TextButton(
                      onPressed: widget.onCreateAccount,
                      child: const Text('Create account'),
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
                                errorBuilder: (_, error, stack) => const Icon(
                                  Icons.broken_image_outlined,
                                  size: 64,
                                ),
                              ),
                            )
                          : ProfileAvatar(
                              url: 'asset:$_preset',
                              size: 144,
                              label: 'Selected avatar',
                            ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy || widget.isGuest ? null : () => _save(),
                      child: const Text('Save picture'),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _preset = null;
                              _photo = null;
                              _error = null;
                            }),
                      child: const Text('Cancel selection'),
                    ),
                  ],
                  if (!preview && !_grid) ...[
                    ListTile(
                      leading: const Icon(Icons.face_outlined),
                      title: const Text('Choose a built-in avatar'),
                      subtitle: const Text(
                        '24 Open Peeps avatars · available offline',
                      ),
                      onTap: _busy ? null : () => setState(() => _grid = true),
                    ),
                    ListTile(
                      leading: const Icon(Icons.photo_library_outlined),
                      title: const Text('Choose from gallery'),
                      onTap: _busy ? null : () => _pick(false),
                    ),
                    ListTile(
                      leading: const Icon(Icons.photo_camera_outlined),
                      title: const Text('Take a photo'),
                      onTap: _busy ? null : () => _pick(true),
                    ),
                    if (_repository.profile?.avatarUrl?.isNotEmpty == true &&
                        !widget.isGuest)
                      ListTile(
                        leading: const Icon(Icons.delete_outline),
                        title: const Text('Remove photo'),
                        onTap: _busy ? null : _remove,
                      ),
                    if (_recovered != null)
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => _pick(false, recovered: _recovered),
                        child: const Text('Recover selected photo'),
                      ),
                  ],
                  if (_grid) ...[
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) => Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: AvatarRepository.presetIds
                            .asMap()
                            .entries
                            .map((entry) {
                              final selected =
                                  _preset == entry.value ||
                                  (_preset == null &&
                                      _repository.profile?.avatarUrl ==
                                          'asset:${entry.value}');
                              final size = ((constraints.maxWidth - 24) / 3)
                                  .clamp(48.0, 100.0);
                              return Semantics(
                                button: true,
                                selected: selected,
                                label: 'Open Peeps avatar ${entry.key + 1}',
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(size),
                                  onTap: _busy
                                      ? null
                                      : () => setState(() {
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
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.outline,
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
                            })
                            .toList(),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _grid = false;
                              _preset = null;
                            }),
                      child: const Text('Back to photo options'),
                    ),
                  ],
                  if (_error != null)
                    Semantics(liveRegion: true, child: Text(_error!)),
                  if (_permissionError)
                    TextButton(
                      onPressed: () => openAppSettings(),
                      child: const Text('Open device settings'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

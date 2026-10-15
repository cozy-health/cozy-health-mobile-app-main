import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:flutter_svg/flutter_svg.dart';
import '../../features/settings/data/avatar_repository.dart';
import '../models/user_profile.dart';
import '../services/local_db_service.dart';

class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({
    super.key,
    this.profile,
    this.size = 48,
    this.url,
    this.label = 'Profile picture',
  });
  final UserProfile? profile;
  final String? url;
  final double size;
  final String label;
  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  String? _retried;
  String? _cacheKey;
  Future<Uint8List?>? _cache;
  void _refresh(String url) {
    final scope = LocalDbService().boxName(LocalDbService.userSettingsBoxName);
    final revision =
        '$scope:${widget.profile?.id}:${widget.profile?.avatarRevision}';
    if (_retried == revision || widget.profile == null) return;
    _retried = revision;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted ||
          scope !=
              LocalDbService().boxName(LocalDbService.userSettingsBoxName)) {
        return;
      }
      try {
        await AvatarRepository().refresh();
      } catch (_) {
        /* Keep the fallback offline. */
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.url ?? widget.profile?.avatarUrl;
    final colors = Theme.of(context).colorScheme;
    final fallback = ColoredBox(
      color: colors.primaryContainer,
      child: Center(
        child: Icon(
          Icons.person_outline,
          color: colors.onPrimaryContainer,
          size: widget.size * .5,
        ),
      ),
    );
    Widget child = fallback;
    if (value != null &&
        value.startsWith('asset:') &&
        AvatarRepository.presetIds.contains(value.substring(6))) {
      child = SvgPicture.asset(
        'assets/avatars/open_peeps/${value.substring(6)}.svg',
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        placeholderBuilder: (_) => fallback,
      );
    } else if (value != null && Uri.tryParse(value)?.scheme == 'https') {
      child = Image.network(
        value,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : fallback,
        errorBuilder: (_, error, stack) {
          _refresh(value);
          return fallback;
        },
      );
      if (widget.profile != null && widget.profile!.avatarRevision > 0) {
        final key =
            '${LocalDbService().boxName(LocalDbService.userSettingsBoxName)}:${widget.profile!.id}:${widget.profile!.avatarRevision}';
        if (_cacheKey != key) {
          _cacheKey = key;
          _cache = AvatarRepository().cachedPhoto(widget.profile!);
        }
        final network = child;
        child = FutureBuilder<Uint8List?>(
          future: _cache,
          builder: (_, snapshot) {
            if (snapshot.data != null) {
              return Image.memory(
                snapshot.data!,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
                errorBuilder: (_, error, stack) => fallback,
              );
            }
            return snapshot.connectionState == ConnectionState.done
                ? network
                : fallback;
          },
        );
      }
    }
    return Semantics(
      image: true,
      label: widget.label,
      child: SizedBox.square(
        dimension: widget.size,
        child: ClipOval(child: child),
      ),
    );
  }
}

import 'dart:async';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../data/avatar_repository.dart';
import '../../services/avatar_photo_picker.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/guest_session_service.dart';
import '../widgets/avatar_picker_sheet.dart';
import 'package:cozy_health/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/services/local_db_service.dart';
import '../../data/profile_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    this.guestLookup,
    this.avatarRepository,
    this.photoPicker,
  });
  final Future<bool> Function()? guestLookup;
  final AvatarRepository? avatarRepository;
  final AvatarPhotoPicker? photoPicker;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool _hasChanges = false;
  bool _saving = false;
  UserProfile? _currentProfile;
  StreamSubscription<UserProfile?>? _profileSubscription;
  bool _pickerOpen = false;
  late String _profileScope;

  @override
  void initState() {
    super.initState();
    _profileScope = LocalDbService().boxName(
      LocalDbService.userSettingsBoxName,
    );
    _loadProfile();
    _profileSubscription = ProfileRepository().watchProfile().listen((profile) {
      if (!mounted) return;
      final scope = LocalDbService().boxName(
        LocalDbService.userSettingsBoxName,
      );
      if (scope != _profileScope) {
        _profileScope = scope;
        nameController.text = profile?.name ?? '';
        usernameController.text = profile?.username ?? '';
        bioController.text = profile?.bio ?? '';
        emailController.text = profile?.email ?? '';
        _hasChanges = false;
      }
      setState(() => _currentProfile = profile);
    });
  }

  void _loadProfile() async {
    final profile = LocalDbService().getUserProfile();
    if (profile != null) {
      _currentProfile = profile;
      nameController.text = profile.name;
      usernameController.text = profile.username ?? '';
      bioController.text = profile.bio ?? '';
      emailController.text = profile.email;
    }
  }

  Future<void> _changePhoto() async {
    if (_pickerOpen) return;
    _pickerOpen = true;
    FocusManager.instance.primaryFocus?.unfocus();
    final scope = LocalDbService().boxName(LocalDbService.userSettingsBoxName);
    try {
      final createAccount = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        builder: (sheetContext) => AvatarPickerSheet(
          repository: widget.avatarRepository,
          picker: widget.photoPicker,
          initialProfile: _currentProfile,
          accountScope: scope,
          guestLookup:
              widget.guestLookup ?? GuestSessionService().isGuestSession,
          onCreateAccount: () => Navigator.pop(sheetContext, true),
        ),
      );
      if (mounted &&
          createAccount == true &&
          scope ==
              LocalDbService().boxName(LocalDbService.userSettingsBoxName)) {
        context.push(AppRouter.createAccount);
      }
    } catch (error, stack) {
      unawaited(Sentry.captureException(error, stackTrace: stack));
      if (mounted) {
        AppSnackbar.show(
          context,
          AppSnackbar.error(
            "We couldn't open picture options. Please try again.",
            onRetry: _changePhoto,
          ),
        );
      }
    } finally {
      _pickerOpen = false;
    }
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    for (final controller in [
      nameController,
      usernameController,
      bioController,
      emailController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onChanged(String _) {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  void _saveChanges() async {
    if (_saving || _currentProfile == null) return;
    setState(() => _saving = true);
    try {
      if (_currentProfile != null) {
        final updated = _currentProfile!.copyWith(
          name: nameController.text.trim(),
          username: usernameController.text.trim(),
          bio: bioController.text.trim(),
          email: emailController.text.trim(),
          updatedAt: DateTime.now(),
        );
        await ProfileRepository().saveProfile(updated);
      }

      if (!mounted) return;
      AppSnackbar.show(
        context,
        AppSnackbar.saved(type: 'user_profile', id: _currentProfile!.id),
      );
      context.pop();
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(
          context,
          AppSnackbar.error(
            "We couldn't save your profile. Please try again.",
            onRetry: _saveChanges,
          ),
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
        ),
        actions: [
          TextButton(
            onPressed: _hasChanges && !_saving ? _saveChanges : null,
            child: Text(
              _saving ? 'Loading...' : 'Save',
              style: AppTextStyles.body1.copyWith(
                color: _hasChanges
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.4),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 24),
              // Avatar
              Center(
                child: Column(
                  children: [
                    InkWell(
                      key: const Key('edit-profile-picture'),
                      onTap: _changePhoto,
                      customBorder: const CircleBorder(),
                      child: Stack(
                        children: [
                          ProfileAvatar(profile: _currentProfile, size: 96),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: CircleAvatar(
                              radius: 16,
                              child: Icon(Icons.edit, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    TextButton(
                      onPressed: _changePhoto,
                      child: Text(
                        'Change photo',
                        style: AppTextStyles.body2.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),

              _FormField(
                label: 'Name',
                controller: nameController,
                onChanged: _onChanged,
              ),
              SizedBox(height: 24),

              _FormField(
                label: 'Username',
                controller: usernameController,
                helperText: 'Letters and numbers only.',
                onChanged: _onChanged,
              ),
              SizedBox(height: 24),

              _FormField(
                label: 'Bio',
                controller: bioController,
                maxLines: 4,
                onChanged: _onChanged,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${bioController.text.length} / 150',
                    style: AppTextStyles.body2.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),

              _FormField(
                label: 'Email',
                controller: emailController,
                helperText: 'Contact support to change.',
                enabled: false,
              ),
              SizedBox(height: 48),

              AppButton(
                text: 'Save Changes',
                isLoading: _saving,
                onPressed: _hasChanges && !_saving ? _saveChanges : null,
              ),
              SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? helperText;
  final int maxLines;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  const _FormField({
    required this.label,
    required this.controller,
    this.helperText,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body2.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          enabled: enabled,
          onChanged: onChanged,
          style: AppTextStyles.body1.copyWith(
            color: enabled
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).brightness == Brightness.dark
                ? AppColors.textMutedDark
                : AppColors.textMutedLight,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
        ),
        if (helperText != null) ...[
          SizedBox(height: 8),
          Text(
            helperText!,
            style: AppTextStyles.body2.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
            ),
          ),
        ],
      ],
    );
  }
}

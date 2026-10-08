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
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool _hasChanges = false;
  UserProfile? _currentProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
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

  void _onChanged(String _) {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  void _saveChanges() async {
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
      AppSnackbar.fromLegacy(content: Text('Profile updated')),
    );
    context.pop();
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
            onPressed: _hasChanges ? _saveChanges : null,
            child: Text(
              'Save',
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
                    Stack(
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.midGrey,
                            image: _currentProfile?.avatarUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(
                                      _currentProfile!.avatarUrl!,
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _currentProfile?.avatarUrl == null
                              ? Icon(
                                  Icons.person,
                                  color: AppColors.white,
                                  size: 48,
                                )
                              : null,
                        ),
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                // show avatar picker
                              },
                              customBorder: const CircleBorder(),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                                ),
                                child: Icon(Icons.edit, color: AppColors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    TextButton(
                      onPressed: () {},
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
                onPressed: _hasChanges ? _saveChanges : null,
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../utils/responsive_extensions.dart';
import '../../data/settings_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final SettingsService _settingsService = SettingsService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController =
      TextEditingController(text: '************');

  bool _loading = true;
  bool _saving = false;
  String? _error;

  String _firstname = '';
  String _lastname = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final response = await _settingsService.getProfile();
      final user = response['user'];
      final profile = user?['profile'];

      _firstname = profile?['firstname']?.toString() ?? '';
      _lastname = profile?['lastname']?.toString() ?? '';

      nameController.text = [_firstname, _lastname]
          .where((value) => value.trim().isNotEmpty)
          .join(' ');

      emailController.text = user?['email']?.toString() ?? '';
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Unable to load profile.';
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final fullName = nameController.text.trim();

    if (fullName.isEmpty) {
      setState(() {
        _error = 'Name is required.';
      });
      return;
    }

    final parts = fullName.split(' ');
    final firstname = parts.first;
    final lastname = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _settingsService.updateProfile(
        firstname: firstname,
        lastname: lastname,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
        ),
      );

      context.pop();
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _error = 'Unable to update profile.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.w),
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    3.sh,

                    Row(
                      children: [
                        GestureDetector(
                          onTap: _saving ? null : () => context.pop(),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.chevron_left,
                                size: 22,
                                color: AppColors.darkGrey,
                              ),
                              Text(
                                'Back',
                                style: AppTextStyles.body2.copyWith(
                                  color: AppColors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Profile',
                              style: AppTextStyles.heading2.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 14.w),
                      ],
                    ),

                    5.sh,

                    Center(
                      child: Container(
                        height: 135,
                        width: 135,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFC9FF6B),
                        ),
                        child: Center(
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor:
                                AppColors.primary.withOpacity(0.15),
                            child: const Icon(
                              Icons.person,
                              size: 58,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),

                    5.sh,

                    if (_error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _error!,
                          style: AppTextStyles.body2.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ),
                      2.sh,
                    ],

                    _label('Name'),
                    _inputField(nameController),

                    2.5.sh,

                    _label('Email'),
                    _inputField(emailController, enabled: false),

                    2.5.sh,

                    _label('Password'),
                    _inputField(
                      passwordController,
                      obscureText: true,
                      enabled: false,
                    ),

                    const Spacer(),

                    AppButton(
                      text: _saving ? 'Saving...' : 'Save',
                      onPressed: _saving ? null : _saveProfile,
                    ),

                    4.sh,
                  ],
                ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Text(
        text,
        style: AppTextStyles.body2.copyWith(
          color: AppColors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _inputField(
    TextEditingController controller, {
    bool obscureText = false,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      enabled: enabled,
      style: AppTextStyles.body1.copyWith(
        fontSize: 14,
        color: enabled ? AppColors.black : AppColors.grey,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: enabled ? AppColors.white : const Color(0xFFF4F5F7),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 4.w,
          vertical: 1.8.h,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFFE1E4EA),
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: Color(0xFFE1E4EA),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
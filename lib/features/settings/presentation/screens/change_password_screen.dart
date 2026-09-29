import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  double _strength = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onNewPasswordChanged(String value) {
    setState(() {
      _strength = (value.length / 12).clamp(0.0, 1.0);
    });
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Mock network
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password changed successfully')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        backgroundColor: AppColors.warmBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        title: Text(
          'Change Password',
          style: AppTextStyles.heading2.copyWith(color: AppColors.text),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              _FormField(
                label: 'Current Password',
                controller: _currentController,
                obscureText: true,
              ),
              const SizedBox(height: 24),
              _FormField(
                label: 'New Password',
                controller: _newController,
                obscureText: true,
                onChanged: _onNewPasswordChanged,
              ),
              const SizedBox(height: 12),
              // Strength bar
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: _strength,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _strength < 0.3
                            ? AppColors.danger
                            : (_strength < 0.7 ? Colors.orange : AppColors.primary),
                      ),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _strength < 0.3
                        ? 'Weak'
                        : (_strength < 0.7 ? 'Fair' : 'Strong'),
                    style: AppTextStyles.body2.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _FormField(
                label: 'Confirm New Password',
                controller: _confirmController,
                obscureText: true,
              ),
              const SizedBox(height: 48),
              AppButton(
                text: _isLoading ? 'Saving...' : 'Save Password',
                onPressed: _isLoading ? null : _save,
              ),
              const SizedBox(height: 48),
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
  final bool obscureText;
  final ValueChanged<String>? onChanged;

  const _FormField({
    required this.label,
    required this.controller,
    this.obscureText = false,
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
            color: AppColors.text,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: label,
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            onChanged: onChanged,
            style: AppTextStyles.body1.copyWith(color: AppColors.text),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

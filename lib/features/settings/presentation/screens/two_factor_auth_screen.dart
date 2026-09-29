import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class TwoFactorAuthScreen extends StatefulWidget {
  const TwoFactorAuthScreen({super.key});

  @override
  State<TwoFactorAuthScreen> createState() => _TwoFactorAuthScreenState();
}

class _TwoFactorAuthScreenState extends State<TwoFactorAuthScreen> {
  bool _isEnabled = false;
  String _setupStep = 'methods'; // methods, qr, backup

  final List<String> _backupCodes = [
    'A1B2-C3D4', 'E5F6-G7H8', 'I9J0-K1L2', 'M3N4-O5P6', 'Q7R8-S9T0',
    'U1V2-W3X4', 'Y5Z6-A7B8', 'C9D0-E1F2', 'G3H4-I5J6', 'K7L8-M9N0'
  ];

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
          'Two-Factor Auth',
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
              if (_isEnabled) ...[
                _buildEnabledState(),
              ] else ...[
                if (_setupStep == 'methods') _buildMethodsState(),
                if (_setupStep == 'qr') _buildQrState(),
                if (_setupStep == 'backup') _buildBackupState(),
              ],
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnabledState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.security, color: AppColors.primary, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '2FA is Enabled',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your account is protected with Authenticator App.',
                      style: AppTextStyles.body2.copyWith(color: AppColors.text),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            children: [
              _SettingsRow(
                icon: Icons.vpn_key_outlined,
                label: 'View Backup Codes',
                onTap: () {
                  setState(() {
                    _isEnabled = false;
                    _setupStep = 'backup';
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Divider(height: 1, thickness: 1, color: AppColors.border.withValues(alpha: 0.4)),
              ),
              _SettingsRow(
                icon: Icons.swap_horiz,
                label: 'Change Method',
                onTap: () {
                  setState(() {
                    _isEnabled = false;
                    _setupStep = 'methods';
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Divider(height: 1, thickness: 1, color: AppColors.border.withValues(alpha: 0.4)),
              ),
              _SettingsRow(
                icon: Icons.gpp_bad_outlined,
                label: 'Disable 2FA',
                isDanger: true,
                onTap: () {
                  _showDisableConfirmation();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMethodsState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Protect Your Account',
          style: AppTextStyles.heading2.copyWith(fontSize: 24, color: AppColors.text),
        ),
        const SizedBox(height: 12),
        Text(
          'Two-factor authentication adds an extra layer of security to your account. Choose a method below.',
          style: AppTextStyles.body1.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            children: [
              _MethodRow(
                title: 'Authenticator App (Recommended)',
                description: 'Use an app like Google Authenticator or Authy to generate codes.',
                icon: Icons.qr_code_scanner,
                onTap: () => setState(() => _setupStep = 'qr'),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Divider(height: 1, thickness: 1, color: AppColors.border.withValues(alpha: 0.4)),
              ),
              _MethodRow(
                title: 'Text Message (SMS)',
                description: 'Receive a 6-digit code via text message.',
                icon: Icons.sms_outlined,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('SMS method coming soon')),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Divider(height: 1, thickness: 1, color: AppColors.border.withValues(alpha: 0.4)),
              ),
              _MethodRow(
                title: 'Email',
                description: 'Receive a 6-digit code via email.',
                icon: Icons.email_outlined,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email method coming soon')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQrState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Set Up Authenticator',
          style: AppTextStyles.heading2.copyWith(fontSize: 24, color: AppColors.text),
        ),
        const SizedBox(height: 12),
        Text(
          'Scan this QR code with your authenticator app, then enter the 6-digit code it generates.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body1.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.qr_code_2, size: 200, color: Colors.black),
        ),
        const SizedBox(height: 32),
        Semantics(
          label: 'Authenticator Code Input',
          child: TextField(
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading2.copyWith(color: AppColors.text, letterSpacing: 8),
            maxLength: 6,
            decoration: InputDecoration(
              hintText: '000000',
              hintStyle: AppTextStyles.heading2.copyWith(color: AppColors.textMuted.withValues(alpha: 0.5), letterSpacing: 8),
              filled: true,
              fillColor: AppColors.surface,
              counterText: '',
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
        const SizedBox(height: 24),
        AppButton(
          text: 'Verify and Continue',
          onPressed: () => setState(() => _setupStep = 'backup'),
        ),
      ],
    );
  }

  Widget _buildBackupState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Backup Codes',
          style: AppTextStyles.heading2.copyWith(fontSize: 24, color: AppColors.text),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Save these somewhere safe! You will need them if you lose access to your device.',
                  style: AppTextStyles.body2.copyWith(color: AppColors.danger, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Wrap(
            spacing: 24,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: _backupCodes.map((code) => SizedBox(
              width: 100,
              child: Text(
                code,
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.text,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 32),
        AppButton(
          text: 'I\'ve Saved My Codes',
          onPressed: () {
            setState(() {
              _isEnabled = true;
              _setupStep = 'methods';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Two-factor authentication enabled!')),
            );
          },
        ),
      ],
    );
  }

  void _showDisableConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Disable 2FA?',
            style: AppTextStyles.heading2.copyWith(color: AppColors.text),
          ),
          content: Text(
            'Your account will be less secure.',
            style: AppTextStyles.body1.copyWith(color: AppColors.text),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => _isEnabled = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Two-factor authentication disabled')),
                );
              },
              child: Text(
                'Disable',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? AppColors.danger : AppColors.text;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body1.copyWith(
                    color: color,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textMuted, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodRow extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _MethodRow({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warmBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTextStyles.body2.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

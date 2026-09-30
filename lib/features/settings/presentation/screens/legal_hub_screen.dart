import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class LegalHubScreen extends StatelessWidget {
  const LegalHubScreen({super.key});

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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Legal',
                style: AppTextStyles.heading1.copyWith(fontSize: 28, color: AppColors.text),
              ),
              const SizedBox(height: 12),
              Text(
                'Everything we commit to.',
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
                    _LegalRow(
                      icon: Icons.description_outlined,
                      label: 'Terms of Service',
                      onTap: () => _pushDocument(context, 'Terms of Service', _mockDocText),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: Divider(height: 1, thickness: 1, color: AppColors.border.withValues(alpha: 0.4)),
                    ),
                    _LegalRow(
                      icon: Icons.lock_outline,
                      label: 'Privacy Policy',
                      onTap: () => _pushDocument(context, 'Privacy Policy', _mockDocText),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: Divider(height: 1, thickness: 1, color: AppColors.border.withValues(alpha: 0.4)),
                    ),
                    _LegalRow(
                      icon: Icons.cookie_outlined,
                      label: 'Cookie Policy',
                      onTap: () => _pushDocument(context, 'Cookie Policy', _mockDocText),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: Divider(height: 1, thickness: 1, color: AppColors.border.withValues(alpha: 0.4)),
                    ),
                    _LegalRow(
                      icon: Icons.code,
                      label: 'Open Source Licenses',
                      onTap: () {
                        showLicensePage(
                          context: context,
                          applicationName: 'Cozy Health',
                          applicationVersion: '1.0.0',
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: Divider(height: 1, thickness: 1, color: AppColors.border.withValues(alpha: 0.4)),
                    ),
                    _LegalRow(
                      icon: Icons.security_outlined,
                      label: 'Data Processing Agreement',
                      onTap: () => _pushDocument(context, 'Data Processing Agreement', _mockDocText),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Last updated: October 1, 2026',
                style: AppTextStyles.body2.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  void _pushDocument(BuildContext context, String title, String content) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _DocumentScreen(title: title, content: content),
      ),
    );
  }

  static const String _mockDocText = 
    "1. Introduction\n\n"
    "Welcome to Cozy Health. These documents outline our commitment to your privacy and the terms under which we provide our services. We believe in plain language and transparency.\n\n"
    "2. Data Privacy\n\n"
    "Your data is yours. We do not sell your data, nor do we share it with third parties for marketing purposes. Your journal entries and mood logs are encrypted and private by default.\n\n"
    "3. Your Rights\n\n"
    "You have the right to export your data at any time. You also have the right to request full deletion of your account and all associated data, which we will honor within 30 days.\n\n"
    "4. Usage Guidelines\n\n"
    "Cozy Health is a tool for self-reflection and is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.\n\n"
    "5. Changes to This Policy\n\n"
    "We may update our policies from time to time. We will notify you of any changes by posting the new policy on this page and updating the 'Last updated' date.\n\n"
    "If you have any questions about this document, please contact us via the Help & Support section.";
}

class _LegalRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _LegalRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.text, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward, color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentScreen extends StatelessWidget {
  final String title;
  final String content;

  const _DocumentScreen({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmBackground,
      appBar: AppBar(
        backgroundColor: AppColors.warmBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.heading1.copyWith(fontSize: 28, color: AppColors.text),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last updated: October 1, 2026',
                    style: AppTextStyles.body2.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    content,
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.text,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

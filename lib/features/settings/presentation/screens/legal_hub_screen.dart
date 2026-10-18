import 'package:cozy_health/core/theme/app_surface.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/consent_service.dart';

class LegalHubScreen extends StatelessWidget {
  const LegalHubScreen({super.key});

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
                style: AppTextStyles.heading1.copyWith(
                  fontSize: 28,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Everything we commit to.',
                style: AppTextStyles.body1.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
              SizedBox(height: 32),

              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: AppSurface.border(context),
                ),
                child: Column(
                  children: [
                    _LegalRow(
                      icon: Icons.description_outlined,
                      label: 'Terms of Service',
                      onTap: () => _pushDocument(
                        context,
                        'Terms of Service',
                        _mockDocText,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.4),
                      ),
                    ),
                    _LegalRow(
                      icon: Icons.lock_outline,
                      label: 'Privacy Policy',
                      onTap: () => _pushDocument(
                        context,
                        'Privacy Policy',
                        _mockDocText,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.4),
                      ),
                    ),
                    _LegalRow(
                      icon: Icons.cookie_outlined,
                      label: 'Cookie Policy',
                      onTap: () =>
                          _pushDocument(context, 'Cookie Policy', _mockDocText),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.4),
                      ),
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
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.4),
                      ),
                    ),
                    _LegalRow(
                      icon: Icons.security_outlined,
                      label: 'Data Processing Agreement',
                      onTap: () => _pushDocument(
                        context,
                        'Data Processing Agreement',
                        _mockDocText,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              Text(
                'Published documents show their configured version. Drafts are not approved policies.',
                style: AppTextStyles.body2.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
              SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pushDocument(
    BuildContext context,
    String title,
    String content,
  ) async {
    var text = 'This document has not been published yet.';
    final type = {
      'Terms of Service': 'tos',
      'Privacy Policy': 'privacy_policy',
    }[title];
    if (type != null) {
      try {
        final response = await ApiClient().get('/config', withAuth: false);
        final raw = response.data['consent']?['documents']?[type];
        if (raw is Map) {
          final document = ConsentDocument(
            type,
            Map<String, dynamic>.from(raw),
          );
          if (document.reviewable) {
            text = 'Version ${document.version}\n\n${document.content}';
          }
        }
      } catch (_) {
        text = 'This document could not be loaded. Please close and retry.';
      }
    }
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _DocumentScreen(title: title, content: text),
      ),
    );
  }

  static const String _mockDocText =
      'This document has not been published yet.';
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
              Icon(
                icon,
                color: Theme.of(context).colorScheme.onSurface,
                size: 24,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body1.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
                size: 20,
              ),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
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
                    style: AppTextStyles.heading1.copyWith(
                      fontSize: 28,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Last updated: October 1, 2026',
                    style: AppTextStyles.body2.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                  SizedBox(height: 32),
                  Text(
                    content,
                    style: AppTextStyles.body1.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

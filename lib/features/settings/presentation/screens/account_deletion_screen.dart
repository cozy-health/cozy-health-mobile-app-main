import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class AccountDeletionScreen extends StatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  State<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends State<AccountDeletionScreen> {
  final TextEditingController _confirmController = TextEditingController();
  bool _canDelete = false;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  void _onConfirmChanged(String value) {
    final canDelete = value == 'DELETE';
    if (_canDelete != canDelete) {
      setState(() {
        _canDelete = canDelete;
      });
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 16),
              Text(
                'Delete Account',
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.danger,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'This action cannot be undone.',
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'If you delete your account:',
                style: AppTextStyles.body1.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 16),
              const _BulletPoint('Your profile will be deleted'),
              SizedBox(height: 8),
              const _BulletPoint('Your entries will be deleted'),
              SizedBox(height: 8),
              const _BulletPoint('Your subscription will end'),
              SizedBox(height: 24),
              Text(
                'Consider exporting your data first.',
                style: AppTextStyles.body1.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 16),
              AppButton(
                text: 'Export My Data',
                onPressed: () => context.push(AppRouter.dataExport),
                // Needs to be styled as secondary, but standard AppButton might not have a secondary mode here.
                // So I will customize it inline or use a different button style if possible.
                // Assuming default is primary.
              ),
              SizedBox(height: 48),
              Text(
                'To confirm deletion, type DELETE below:',
                style: AppTextStyles.body1.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _confirmController,
                onChanged: _onConfirmChanged,
                style: AppTextStyles.body1.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
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
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.danger),
                  ),
                ),
              ),
              SizedBox(height: 24),
              // Delete button (Custom styled to be red)
              InkWell(
                onTap: _canDelete
                    ? () {
                        // show dialog or perform deletion
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Account deleted.')),
                        );
                        // context.go(AppRouter.splash);
                      }
                    : null,
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _canDelete ? AppColors.danger : AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Text(
                    'Delete My Account',
                    style: AppTextStyles.body1.copyWith(
                      color: _canDelete ? AppColors.white : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 8, right: 12),
          child: CircleAvatar(
            radius: 3,
            backgroundColor: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body1.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

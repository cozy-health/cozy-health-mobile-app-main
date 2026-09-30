import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class DataExportScreen extends StatelessWidget {
  const DataExportScreen({super.key});

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
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'Export my data',
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Get a copy of everything you\'ve shared with Cozy. This includes:',
                style: AppTextStyles.body1.copyWith(color: AppColors.text),
              ),
              const SizedBox(height: 16),
              _BulletPoint('Journal entries'),
              const SizedBox(height: 8),
              _BulletPoint('Mood logs'),
              const SizedBox(height: 8),
              _BulletPoint('AI Conversations'),
              const SizedBox(height: 8),
              _BulletPoint('Account details'),
              const SizedBox(height: 24),
              Text(
                'Your data will be exported as a .ZIP file containing JSON and text files.',
                style: AppTextStyles.body1.copyWith(color: AppColors.text),
              ),
              const SizedBox(height: 24),
              Text(
                'It may take up to 24 hours to process your request. We\'ll email you when it\'s ready.',
                style: AppTextStyles.body1.copyWith(color: AppColors.text),
              ),
              const SizedBox(height: 48),
              AppButton(
                text: 'Request Data Export',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export requested. Check your email.')),
                  );
                  context.pop();
                },
              ),
              const SizedBox(height: 48),
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
        const Padding(
          padding: EdgeInsets.only(top: 8, right: 12),
          child: CircleAvatar(
            radius: 3,
            backgroundColor: AppColors.text,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body1.copyWith(color: AppColors.text),
          ),
        ),
      ],
    );
  }
}

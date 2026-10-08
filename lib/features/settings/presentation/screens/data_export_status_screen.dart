import 'package:cozy_health/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

enum ExportState { empty, preparing, ready, failed }

class DataExportStatusScreen extends StatefulWidget {
  const DataExportStatusScreen({super.key});

  @override
  State<DataExportStatusScreen> createState() => _DataExportStatusScreenState();
}

class _DataExportStatusScreenState extends State<DataExportStatusScreen> {
  // Mock state
  ExportState _currentState = ExportState.ready;

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Data export status',
                style: AppTextStyles.heading1.copyWith(
                  fontSize: 28,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'View the status of your requested data export.',
                style: AppTextStyles.body1.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
              SizedBox(height: 48),

              Expanded(child: _buildStateContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateContent() {
    switch (_currentState) {
      case ExportState.empty:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_open,
                size: 64,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textSubtleDark
                    : AppColors.textSubtleLight,
              ),
              SizedBox(height: 24),
              Text(
                'No active export',
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 24,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'You haven\'t requested a data export yet.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body1.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
              SizedBox(height: 32),
              AppButton(
                text: 'Request Data Export',
                onPressed: () {
                  // Navigate to data export request screen (already exists)
                  // context.push(AppRouter.dataExport);
                  setState(() => _currentState = ExportState.preparing);
                },
              ),
              SizedBox(height: 64),
            ],
          ),
        );

      case ExportState.preparing:
        return Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                SizedBox(height: 32),
                Text(
                  'Preparing your data',
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 20,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'This usually takes up to 24 hours. We\'ll email you when it\'s ready.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body1.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
        );

      case ExportState.ready:
        return Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, size: 32, color: AppColors.white),
                ),
                SizedBox(height: 24),
                Text(
                  'Your data is ready',
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 20,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Requested on Oct 1, 2026',
                  style: AppTextStyles.body2.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'This link will expire in 7 days for your security.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body2.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
                SizedBox(height: 32),
                AppButton(
                  text: 'Download Data (ZIP)',
                  onPressed: () {
                    AppSnackbar.show(
                      context,
                      AppSnackbar.fromLegacy(
                        content: Text(
                          'Downloading file... Check your Downloads folder.',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );

      case ExportState.failed:
        return Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.danger),
                SizedBox(height: 24),
                Text(
                  'Export failed',
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 20,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Something went wrong while preparing your data export. Please try again.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body1.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 32),
                AppButton(
                  text: 'Retry Export',
                  onPressed: () {
                    setState(() => _currentState = ExportState.preparing);
                  },
                ),
              ],
            ),
          ),
        );
    }
  }
}

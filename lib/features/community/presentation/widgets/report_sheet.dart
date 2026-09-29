import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class ReportSheet extends StatefulWidget {
  final VoidCallback onSubmit;

  const ReportSheet({super.key, required this.onSubmit});

  static void show(BuildContext context, {required VoidCallback onSubmit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ReportSheet(onSubmit: onSubmit),
      ),
    );
  }

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  String? _selectedReason;
  final TextEditingController _notesController = TextEditingController();

  final List<String> _reasons = [
    'Harassment or hate speech',
    'Encourages harm',
    'Spam or scam',
    'Shares private info',
    'Something else',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('What\'s wrong?', style: AppTextStyles.heading3),
          const SizedBox(height: 16),
          ..._reasons.map((reason) => _buildRadio(reason)),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              hintText: 'Additional notes (optional)',
              hintStyle: AppTextStyles.body1.copyWith(color: AppColors.textMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              filled: true,
              fillColor: AppColors.background,
            ),
            maxLines: 3,
            style: AppTextStyles.body1,
          ),
          const SizedBox(height: 24),
          AppButton(
            text: 'Submit report',
            onPressed: _selectedReason == null
                ? null
                : () {
                    Navigator.pop(context);
                    widget.onSubmit();
                  },
          ),
          const SizedBox(height: 12),
          AppButton(
            text: 'Cancel',
            isOutlined: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildRadio(String reason) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedReason = reason;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              _selectedReason == reason ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: _selectedReason == reason ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                reason,
                style: AppTextStyles.body1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

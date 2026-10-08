import 'package:cozy_health/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class DownloadMyDataScreen extends StatefulWidget {
  const DownloadMyDataScreen({super.key});

  @override
  State<DownloadMyDataScreen> createState() => _DownloadMyDataScreenState();
}

class _DownloadMyDataScreenState extends State<DownloadMyDataScreen> {
  String _selectedRange = 'Last 30 days';
  final List<String> _ranges = [
    'Last 7 days',
    'Last 30 days',
    'Last 90 days',
    'Custom',
  ];

  bool _includeMood = true;
  bool _includeJournal = true;
  bool _includeAi = false;

  bool _isGenerating = false;

  void _generatePdf() async {
    setState(() => _isGenerating = true);
    // Mock generation time
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() => _isGenerating = false);
    AppSnackbar.show(
      context,
      AppSnackbar.fromLegacy(content: Text('PDF ready. Check your Downloads.')),
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
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Download my data',
                      style: AppTextStyles.heading1.copyWith(
                        fontSize: 28,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Generate a PDF summary of your data to share with your healthcare provider or keep for yourself.',
                      style: AppTextStyles.body1.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                    SizedBox(height: 32),

                    Text(
                      'Date range',
                      style: AppTextStyles.body2.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedRange,
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColors.textSubtleDark
                                : AppColors.textSubtleLight,
                          ),
                          isExpanded: true,
                          style: AppTextStyles.body1.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          items: _ranges.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              setState(() => _selectedRange = newValue);
                            }
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: 32),
                    Text(
                      'Include',
                      style: AppTextStyles.body2.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _CheckboxRow(
                            label: 'Mood entries',
                            value: _includeMood,
                            onChanged: (val) =>
                                setState(() => _includeMood = val ?? false),
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
                          _CheckboxRow(
                            label: 'Journal entries',
                            value: _includeJournal,
                            onChanged: (val) =>
                                setState(() => _includeJournal = val ?? false),
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
                          _CheckboxRow(
                            label: 'AI conversations',
                            value: _includeAi,
                            onChanged: (val) =>
                                setState(() => _includeAi = val ?? false),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 48),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: AppButton(
                text: _isGenerating ? 'Generating...' : 'Generate PDF',
                onPressed:
                    _isGenerating ||
                        (!_includeMood && !_includeJournal && !_includeAi)
                    ? null
                    : _generatePdf,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckboxRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _CheckboxRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body1.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textSubtleDark
                      : AppColors.textSubtleLight.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

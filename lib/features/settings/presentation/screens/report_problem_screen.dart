import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final TextEditingController _descController = TextEditingController();
  String _selectedCategory = 'Bug';
  bool _isLoading = false;
  bool _hasImage = false; // mock image attach

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_descController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Mock network
    if (!mounted) return;
    
    setState(() => _isLoading = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report submitted. Thanks for helping us improve.')),
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Report a problem',
                style: AppTextStyles.heading1.copyWith(fontSize: 28, color: AppColors.text),
              ),
              const SizedBox(height: 32),
              
              Text(
                'What\'s happening?',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSubtle),
                    isExpanded: true,
                    style: AppTextStyles.body1.copyWith(color: AppColors.text),
                    items: ['Bug', 'Suggestion', 'Crash', 'Other'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() => _selectedCategory = newValue);
                      }
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              Text(
                'Describe the issue',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Semantics(
                label: 'Issue description input',
                child: TextField(
                  controller: _descController,
                  maxLines: 5,
                  onChanged: (_) => setState(() {}),
                  style: AppTextStyles.body1.copyWith(color: AppColors.text),
                  decoration: InputDecoration(
                    hintText: 'Please provide as much detail as possible...',
                    hintStyle: AppTextStyles.body1.copyWith(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.all(16),
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
              Text(
                'Screenshot (optional)',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              if (_hasImage)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.image, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'screenshot_123.jpg',
                          style: AppTextStyles.body1.copyWith(color: AppColors.text),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textSubtle),
                        onPressed: () => setState(() => _hasImage = false),
                      ),
                    ],
                  ),
                )
              else
                InkWell(
                  onTap: () => setState(() => _hasImage = true),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                          const SizedBox(height: 4),
                          Text(
                            'Add image',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
              const SizedBox(height: 32),
              Text(
                'App info',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('v1.0.0 (build 42)', style: AppTextStyles.body1.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    Text('iPhone 14 Pro', style: AppTextStyles.body1.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    Text('iOS 17.5', style: AppTextStyles.body1.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              AppButton(
                text: _isLoading ? 'Submitting...' : 'Submit',
                onPressed: _descController.text.trim().isEmpty || _isLoading ? null : _submit,
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
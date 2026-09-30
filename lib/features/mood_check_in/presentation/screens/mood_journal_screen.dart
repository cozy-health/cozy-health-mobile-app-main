import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_exceptions.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../utils/responsive_extensions.dart';

import '../../data/mood_service.dart';

class MoodJournalScreen extends StatefulWidget {
  final int selectedFeelingExpId;
  final int intensity;
  final List<int> selectedReasonIds;
  final List<int> selectedCopingIds;

  const MoodJournalScreen({
    super.key,
    required this.selectedFeelingExpId,
    required this.intensity,
    required this.selectedReasonIds,
    required this.selectedCopingIds,
  });

  @override
  State<MoodJournalScreen> createState() =>
      _MoodJournalScreenState();
}

class _MoodJournalScreenState
    extends State<MoodJournalScreen> {
  final MoodService _moodService = MoodService();

  final TextEditingController _journalController =
      TextEditingController();

  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  Future<void> _submitMoodCheckin() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await _moodService.submitMoodCheckin(
        feelingExpId: widget.selectedFeelingExpId,
        intensity: widget.intensity,
        reasonIds: widget.selectedReasonIds,
        copingMechanismIds: widget.selectedCopingIds,
        journal: _journalController.text.trim(),
      );

      if (!mounted) return;

      context.go(AppRouter.moodSuccess);
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _error =
            'Unable to save mood check-in.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.black,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Would you like to journal about this moment?',
          style: AppTextStyles.heading2.copyWith(
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.close,
              color: AppColors.black,
            ),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 6.w,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            4.sh,

            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style:
                      AppTextStyles.body2.copyWith(
                    color: Colors.red,
                  ),
                ),
              ),
              2.sh,
            ],

            Text(
              'Start writing ...',
              style:
                  AppTextStyles.body1.copyWith(
                color: AppColors.grey,
                fontSize: 16,
              ),
            ),

            3.sh,

            Expanded(
              child: TextField(
                controller: _journalController,
                maxLines: null,
                expands: true,
                textAlignVertical:
                    TextAlignVertical.top,
                style:
                    AppTextStyles.body1.copyWith(
                  color: AppColors.black,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Write your thoughts here...',
                  hintStyle:
                      AppTextStyles.body1.copyWith(
                    color: AppColors.grey,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(6.w),
        child: AppButton(
          text: _isSubmitting
              ? 'Saving...'
              : 'Continue',
          onPressed: _isSubmitting
              ? null
              : _submitMoodCheckin,
        ),
      ),
    );
  }
}

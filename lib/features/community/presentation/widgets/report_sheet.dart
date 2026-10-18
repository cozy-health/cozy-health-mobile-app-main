import 'package:cozy_health/core/theme/app_surface.dart';
import 'package:flutter/material.dart';
import '../community_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/data/demo_mode.dart';

class ReportSheet extends StatefulWidget {
  final VoidCallback onSubmit;
  final Future<void> Function(String reason, String details)? onReport;

  const ReportSheet({super.key, required this.onSubmit, this.onReport});

  static void show(
    BuildContext context, {
    required VoidCallback onSubmit,
    Future<void> Function(String, String)? onReport,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ReportSheet(onSubmit: onSubmit, onReport: onReport),
      ),
    );
  }

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  String? _selectedReason;
  bool _sending = false;
  String? _error;
  Future<void> _send() async {
    if (_sending || _selectedReason == null) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      if (widget.onReport != null) {
        await widget.onReport!(_selectedReason!, _notesController.text.trim());
      } else if (!DemoMode.instance.enabled) {
        throw UnsupportedError('Reporting is not available here yet.');
      }
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSubmit();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not submit this report. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

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
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          border: AppSurface.border(context),
          color: Theme.of(context).bottomSheetTheme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('What\'s wrong?', style: context.communityHeading3),
            const SizedBox(height: 16),
            ..._reasons.map((reason) => _buildRadio(reason)),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Additional notes (optional)',
                hintStyle: context.communityBody1.copyWith(
                  color: context.communityMuted,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: context.communityBorder.withValues(alpha: 0.7),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: context.communityBorder.withValues(alpha: 0.7),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                filled: true,
                fillColor: context.communityBackground,
              ),
              maxLines: 3,
              style: context.communityBody1,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Submit report',
              isLoading: _sending,
              onPressed: _selectedReason == null || _sending ? null : _send,
            ),
            if (_error != null) Text(_error!),
            const SizedBox(height: 12),
            AppButton(
              text: 'Cancel',
              isOutlined: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
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
              _selectedReason == reason
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: _selectedReason == reason
                  ? Theme.of(context).colorScheme.primary
                  : context.communityMuted,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(reason, style: context.communityBody1)),
          ],
        ),
      ),
    );
  }
}

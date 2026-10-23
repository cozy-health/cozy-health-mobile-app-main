import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/data/demo_mode.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/widgets/wellness_sheet.dart';
import '../../../../core/widgets/wellness_panel.dart';

class ReportSheet extends StatefulWidget {
  const ReportSheet({super.key, required this.onSubmit, this.onReport});
  final VoidCallback onSubmit;
  final Future<void> Function(String reason, String details)? onReport;
  static void show(
    BuildContext context, {
    required VoidCallback onSubmit,
    Future<void> Function(String, String)? onReport,
  }) {
    showWellnessSheet<void>(
      context: context,
      dismissible: false,
      builder: (_) => ReportSheet(onSubmit: onSubmit, onReport: onReport),
    );
  }

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  final _notesController = TextEditingController();
  final _owner = LocalDbService().activeUserId;
  StreamSubscription<void>? _account;
  String? _selectedReason, _error;
  bool _sending = false, _validScope = true;
  static const _reasons = [
    'Harassment or hate speech',
    'Encourages harm',
    'Spam or scam',
    'Shares private info',
    'Something else',
  ];
  bool get _current => _validScope && _owner == LocalDbService().activeUserId;
  @override
  void initState() {
    super.initState();
    _account = LocalDbService().accountChanges.listen((_) {
      if (mounted && !_current) {
        _notesController.clear();
        setState(() {
          _validScope = false;
          _sending = false;
          _selectedReason = null;
          _error = 'The account changed. Close this report and reopen it.';
        });
      }
    });
  }

  @override
  void dispose() {
    _account?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending || _selectedReason == null || !_current) return;
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
      if (!mounted || !_current) return;
      Navigator.pop(context);
      widget.onSubmit();
    } catch (_) {
      if (mounted && _current) {
        setState(() => _error = 'Could not submit this report. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness;
    return WellnessSheet(
      title: 'Report a post',
      busy: _sending,
      children: [
        const Text(
          'Choose a reason. Your report is sent privately to moderators.',
        ),
        SizedBox(height: w.gap),
        for (final reason in _reasons)
          WellnessSheetOption(
            key: ValueKey('report-reason-${_reasons.indexOf(reason)}'),
            label: reason,
            icon: Icons.radio_button_unchecked,
            selected: _selectedReason == reason,
            onPressed: _sending || !_current
                ? null
                : () => setState(() => _selectedReason = reason),
          ),
        SizedBox(height: w.contentGap),
        TextField(
          key: const ValueKey('report-details'),
          controller: _notesController,
          enabled: !_sending && _current,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Additional details (optional)',
          ),
        ),
        SizedBox(height: w.gap),
        if (_error != null) ...[
          Semantics(liveRegion: true, child: Text(_error!)),
          SizedBox(height: w.small),
        ],
        WellnessAction(
          key: const ValueKey('report-submit'),
          label: _sending ? 'Submitting report…' : 'Submit report',
          filled: true,
          onPressed: _selectedReason == null || _sending || !_current
              ? null
              : _send,
        ),
        SizedBox(height: w.small),
        WellnessAction(
          label: 'Cancel',
          onPressed: _sending ? null : () => Navigator.pop(context),
        ),
      ],
    );
  }
}

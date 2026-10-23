import '../../../../core/widgets/wellness_sheet.dart';
import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/response_data.dart';
import '../../../../core/services/network_status.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/widgets/wellness_panel.dart';
import 'shared_record_card.dart';

/// Pagination stays in one sheet, with the existing consent-filtered previews.
class ProviderRecordPicker extends StatefulWidget {
  const ProviderRecordPicker({
    super.key,
    required this.api,
    required this.path,
    required this.type,
    required this.title,
    required this.isCurrent,
    required this.selected,
    this.scopeChanges,
  });
  final ApiClient api;
  final String path, type, title;
  final bool Function() isCurrent;
  final List<Map<String, dynamic>> selected;
  final Listenable? scopeChanges;
  @override
  State<ProviderRecordPicker> createState() => _ProviderRecordPickerState();
}

class _ProviderRecordPickerState extends State<ProviderRecordPicker> {
  final _rows = <Map<String, dynamic>>[];
  int _page = 0, _last = 1;
  bool _busy = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    widget.scopeChanges?.addListener(_scopeChanged);
    _load();
  }

  void _scopeChanged() {
    if (mounted && !widget.isCurrent()) {
      setState(() {
        _rows.clear();
        _busy = false;
        _error =
            'The account or conversation changed. Close this picker and reopen it.';
      });
    }
  }

  @override
  void dispose() {
    widget.scopeChanges?.removeListener(_scopeChanged);
    super.dispose();
  }

  Future<void> _load() async {
    if (!widget.isCurrent()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (networkOffline.value == true) throw StateError('Offline');
      final result = responseMap(
        await widget.api.get(
          '${widget.path}/records',
          query: {'type': widget.type, 'page': _page + 1},
        ),
      );
      if (!mounted || !widget.isCurrent()) return;
      final rows = (result['data'] as List).map(
        (e) => Map<String, dynamic>.from(e as Map),
      );
      setState(() {
        _rows.addAll(
          rows.where(
            (r) => !_rows.any(
              (old) => old['id'] == r['id'] && old['type'] == r['type'],
            ),
          ),
        );
        _page = (result['current_page'] as num?)?.toInt() ?? _page + 1;
        _last = (result['last_page'] as num?)?.toInt() ?? _page;
      });
    } catch (_) {
      if (mounted && widget.isCurrent()) {
        setState(
          () => _error =
              'Unable to load records. Check your connection and sharing permissions.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness;
    return WellnessSheet(
      title: 'Select ${widget.title}',
      children: [
        Text('${widget.selected.length} of 10 records selected'),
        SizedBox(height: w.gap),
        if (_rows.isEmpty && !_busy && _error == null)
          const Text('No records available for sharing.'),
        for (final row in _rows) ...[
          SharedRecordCard(record: row, preview: true),
          WellnessAction(
            label:
                widget.selected.any(
                  (r) => r['id'] == row['id'] && r['type'] == row['type'],
                )
                ? 'Already selected'
                : 'Select record',
            onPressed:
                !widget.isCurrent() ||
                    widget.selected.any(
                      (r) => r['id'] == row['id'] && r['type'] == row['type'],
                    )
                ? null
                : () => Navigator.pop(context, row),
          ),
          SizedBox(height: w.gap),
        ],
        if (_busy) const Center(child: CircularProgressIndicator()),
        if (_error != null) ...[
          Semantics(liveRegion: true, child: Text(_error!)),
          WellnessAction(
            label: 'Retry records',
            onPressed: _busy || !widget.isCurrent() ? null : _load,
          ),
        ],
        if (_page < _last && !_busy && widget.isCurrent())
          WellnessAction(label: 'Load more records', onPressed: _load),
      ],
    );
  }
}

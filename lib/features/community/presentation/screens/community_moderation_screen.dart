import 'package:flutter/material.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/widgets/wellness_panel.dart';
import '../../data/community_moderation_state.dart';

class CommunityModerationScreen extends StatefulWidget {
  const CommunityModerationScreen({super.key, this.state});
  final CommunityModerationState? state;
  @override
  State<CommunityModerationScreen> createState() =>
      _CommunityModerationScreenState();
}

class _CommunityModerationScreenState extends State<CommunityModerationScreen> {
  late final CommunityModerationState _state;
  final _owner = LocalDbService().activeUserId;
  final _controllers = <String, TextEditingController>{};
  String? _busy, _message;
  @override
  void initState() {
    super.initState();
    _state = widget.state ?? CommunityModerationState.instance;
    _state.addListener(_changed);
    _state.refresh();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _state.removeListener(_changed);
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit(String id) async {
    if (_busy != null || _owner != LocalDbService().activeUserId) return;
    final message = _controllers[id]?.text.trim() ?? '';
    if (message.length < 5 || message.length > 2000) {
      setState(() => _message = 'Write between 5 and 2000 characters.');
      return;
    }
    setState(() {
      _busy = id;
      _message = null;
    });
    try {
      await _state.appeal(id, message);
      if (mounted && _owner == LocalDbService().activeUserId) {
        setState(
          () => _message =
              'Appeal submitted. Your status will update after review.',
        );
      }
    } catch (_) {
      if (mounted && _owner == LocalDbService().activeUserId) {
        setState(
          () => _message =
              'Could not submit the appeal. Your text is preserved; refresh and retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = context.cozyColors.wellness;
    final sameOwner = _owner == LocalDbService().activeUserId;
    final data = sameOwner ? _state.data : null;
    final decisions = data?['decisions'] is List
        ? (data!['decisions'] as List).whereType<Map>().toList()
        : <Map>[];
    final appeals = data?['appeals'] is List
        ? (data!['appeals'] as List).whereType<Map>().toList()
        : <Map>[];
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(w.page),
          children: [
            WellnessAction(
              label: 'Back',
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.of(context).pop(),
            ),
            SizedBox(height: w.gap),
            Text(
              'Community moderation',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: w.gap),
            if (!sameOwner)
              const Text(
                'Your account changed. Close this screen and reopen it to continue.',
              )
            else ...[
              const Text(
                'Review restrictions and content decisions. You can submit one appeal per decision. Notices are shown in the app and sent by email. No response time is promised.',
              ),
              SizedBox(height: w.gap),
              WellnessAction(
                label: 'Refresh moderation status',
                onPressed: _busy == null ? _state.refresh : null,
              ),
              if (_state.error != null) Text(_state.error!),
              if (_message != null)
                Semantics(liveRegion: true, child: Text(_message!)),
              if (data == null && _state.error == null)
                const Text('Loading moderation status...'),
              if (data != null && decisions.isEmpty)
                const Text('No moderation decisions.'),
              for (final decision in decisions) ...[
                SizedBox(height: w.gap),
                WellnessPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${decision['kind'] == 'ban' ? 'Participation restriction' : 'Content decision'} · ${decision['status']}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text('${decision['reason'] ?? ''}'),
                      if (decision['expires_at'] != null)
                        Text(
                          'Expires ${DateTime.tryParse('${decision['expires_at']}')?.toLocal() ?? decision['expires_at']}',
                        ),
                      if (decision['kind'] == 'ban' &&
                          decision['status'] == 'active')
                        const Text(
                          'Reading, reporting, blocking and appeals remain available.',
                        ),
                      for (final appeal in appeals.where(
                        (row) => row['decision_id'] == decision['id'],
                      )) ...[
                        Text('Appeal: ${appeal['status']}'),
                        if (appeal['outcome'] != null)
                          Text('${appeal['outcome']}'),
                      ],
                      if (decision['status'] == 'active' &&
                          !appeals.any(
                            (row) => row['decision_id'] == decision['id'],
                          )) ...[
                        SizedBox(height: w.small),
                        TextField(
                          controller: _controllers.putIfAbsent(
                            '${decision['id']}',
                            TextEditingController.new,
                          ),
                          minLines: 2,
                          maxLines: 6,
                          maxLength: 2000,
                          enabled: _busy == null,
                          decoration: const InputDecoration(
                            labelText: 'Why should this decision be reviewed?',
                          ),
                        ),
                        WellnessAction(
                          label: _busy == decision['id']
                              ? 'Submitting appeal...'
                              : 'Submit appeal',
                          onPressed: _busy == null
                              ? () => _submit('${decision['id']}')
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

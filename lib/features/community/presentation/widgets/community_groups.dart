import 'package:cozy_health/core/theme/app_surface.dart';
import 'dart:async';
// TODO: wire to backend when endpoint exists
import 'package:flutter/material.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/chip.dart' as design;
import '../community_local_state.dart';
import '../../data/community_repository.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/data/demo_mode.dart';
import '../../../../core/services/local_db_service.dart';

class CommunityGroups extends StatefulWidget {
  const CommunityGroups({super.key});
  @override
  State<CommunityGroups> createState() => _CommunityGroupsState();
}

class _CommunityGroupsState extends State<CommunityGroups> {
  String _topic = 'All';
  List<CommunityGroup> _liveGroups = [];
  bool _loading = false;
  String? _error;
  final Set<String> _busy = {};
  StreamSubscription<void>? _account;
  @override
  void initState() {
    super.initState();
    _account = LocalDbService().accountChanges.listen((_) {
      if (mounted) {
        setState(() {
          _liveGroups = [];
          _error = 'Account changed. Reopen groups.';
        });
      }
    });
    if (!DemoMode.instance.enabled) _load();
  }

  @override
  void dispose() {
    _account?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final owner = LocalDbService().activeUserId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await CommunityRepository.pages('/community/groups');
      if (!mounted || owner != LocalDbService().activeUserId) return;
      setState(
        () => _liveGroups = rows
            .map(
              (row) => CommunityGroup(
                id: row['id'].toString(),
                name: row['name'] as String,
                topic: '',
                description: row['description'] as String? ?? '',
                members: (row['member_count'] as num?)?.toInt() ?? 0,
                joined: row['joined'] == true,
              ),
            )
            .toList(),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Groups could not be loaded. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(CommunityGroup group) async {
    if (DemoMode.instance.enabled) {
      CommunityLocalState.instance.toggleMembership(group);
      return;
    }
    if (!_busy.add(group.id)) return;
    final owner = LocalDbService().activeUserId;
    setState(() => _error = null);
    try {
      if (group.joined) {
        await ApiClient().delete('/community/groups/${group.id}/leave');
      } else {
        await ApiClient().post('/community/groups/${group.id}/join');
      }
      if (!mounted || owner != LocalDbService().activeUserId) return;
      await _load();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Membership could not be saved. Please retry.');
      }
    } finally {
      _busy.remove(group.id);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: CommunityLocalState.instance,
    builder: (context, _) {
      final state = CommunityLocalState.instance;
      final groups = (DemoMode.instance.enabled ? state.groups : _liveGroups)
          .where((group) => _topic == 'All' || group.topic == _topic)
          .toList();
      final joined = groups.where((group) => group.joined).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_error != null) ...[
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
          Text(
            'Discover groups',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final topic in [
                  'All',
                  if (DemoMode.instance.enabled) ...CommunityLocalState.topics,
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: design.Chip(
                      label: topic,
                      selected: _topic == topic,
                      variant: design.ChipVariant.topic,
                      onTap: () => setState(() => _topic = topic),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (!_loading && _error == null && groups.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No groups in this topic yet.'),
            ),
          for (final group in groups)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CommunityGroupCard(
                group: group,
                onJoin: () => _toggle(group),
              ),
            ),
          const SizedBox(height: 12),
          Text('Your groups', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (joined.isEmpty) const Text('Join a group to see it here.'),
          for (final group in joined)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CommunityGroupRow(
                group: group,
                onLeave: () => _toggle(group),
              ),
            ),
        ],
      );
    },
  );
}

class CommunityGroupCard extends StatelessWidget {
  const CommunityGroupCard({
    super.key,
    required this.group,
    required this.onJoin,
  });
  final CommunityGroup group;
  final VoidCallback onJoin;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border.all(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.borderDefaultDark
            : AppColors.borderDefault,
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 15,
              child: Icon(Icons.favorite, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text(
                    '${group.members} members',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(group.description),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: group.joined
              ? OutlinedButton(
                  onPressed: onJoin,
                  child: const Text('Joined · Leave'),
                )
              : FilledButton(
                  onPressed: onJoin,
                  child: const Text('Join group'),
                ),
        ),
      ],
    ),
  );
}

class CommunityGroupRow extends StatelessWidget {
  const CommunityGroupRow({
    super.key,
    required this.group,
    required this.onLeave,
  });
  final CommunityGroup group;
  final VoidCallback onLeave;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(border: AppSurface.border(context)),
    child: ListTile(
      leading: const CircleAvatar(
        radius: 15,
        child: Icon(Icons.favorite, size: 16),
      ),
      title: Text(group.name),
      subtitle: Text('${group.members + 1} members'),
      trailing: IconButton(
        tooltip: 'Leave group',
        onPressed: onLeave,
        icon: const Icon(Icons.logout),
      ),
    ),
  );
}

class CreateCommunityGroupScreen extends StatefulWidget {
  const CreateCommunityGroupScreen({super.key});
  @override
  State<CreateCommunityGroupScreen> createState() =>
      _CreateCommunityGroupScreenState();
}

class _CreateCommunityGroupScreenState
    extends State<CreateCommunityGroupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  String _topic = CommunityLocalState.topics.first;
  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create group')),
    body: !DemoMode.instance.enabled
        ? const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Groups are curated by administrators. Creating a group from the patient app is not available yet.',
            ),
          )
        : SafeArea(
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _name,
                    maxLength: 80,
                    decoration: const InputDecoration(labelText: 'Group name'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a group name'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  AppDropdown<String>(
                    value: _topic,
                    label: const Text('Topic'),
                    entries: CommunityLocalState.topics
                        .map(
                          (topic) =>
                              DropdownMenuEntry(value: topic, label: topic),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _topic = value!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _description,
                    maxLength: 500,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Add a description'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      if (!_form.currentState!.validate()) return;
                      CommunityLocalState.instance.createGroup(
                        name: _name.text,
                        topic: _topic,
                        description: _description.text,
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Text('Save group'),
                  ),
                ],
              ),
            ),
          ),
  );
}

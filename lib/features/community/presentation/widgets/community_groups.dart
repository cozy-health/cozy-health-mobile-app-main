// TODO: wire to backend when endpoint exists
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/chip.dart' as design;
import '../community_local_state.dart';

class CommunityGroups extends StatefulWidget {
  const CommunityGroups({super.key});
  @override
  State<CommunityGroups> createState() => _CommunityGroupsState();
}

class _CommunityGroupsState extends State<CommunityGroups> {
  String _topic = 'All';
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: CommunityLocalState.instance,
    builder: (context, _) {
      final state = CommunityLocalState.instance;
      final groups = state.groups
          .where((group) => _topic == 'All' || group.topic == _topic)
          .toList();
      final joined = groups.where((group) => group.joined).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Featured Groups',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final topic in ['All', ...CommunityLocalState.topics])
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
          if (groups.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No groups in this topic yet.'),
            ),
          for (final group in groups)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CommunityGroupCard(
                group: group,
                onJoin: () => state.toggleMembership(group),
              ),
            ),
          const SizedBox(height: 12),
          Text('My Group', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (joined.isEmpty) const Text('Join a group to see it here.'),
          for (final group in joined)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CommunityGroupRow(
                group: group,
                onLeave: () => state.toggleMembership(group),
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
                    '${group.members + (group.joined ? 1 : 0)} members',
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
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).dividerColor),
      borderRadius: BorderRadius.circular(8),
    ),
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
    body: SafeArea(
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
            DropdownButtonFormField<String>(
              initialValue: _topic,
              decoration: const InputDecoration(labelText: 'Topic'),
              items: CommunityLocalState.topics
                  .map(
                    (topic) =>
                        DropdownMenuItem(value: topic, child: Text(topic)),
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

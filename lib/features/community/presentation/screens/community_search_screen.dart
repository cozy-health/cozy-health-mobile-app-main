import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/widgets/wellness_panel.dart';
import '../../../../core/data/demo_mode.dart';
import '../../data/community_repository.dart';
import '../community_local_state.dart';
import '../widgets/post_card.dart';
import '../widgets/post_actions.dart';

class CommunitySearchScreen extends StatefulWidget {
  const CommunitySearchScreen({super.key});
  @override
  State<CommunitySearchScreen> createState() => _CommunitySearchScreenState();
}

class _CommunitySearchScreenState extends State<CommunitySearchScreen> {
  final _query = TextEditingController();
  List<Map<String, dynamic>> _posts = [], _groups = [];
  String? _error;
  bool _loading = true;
  int _tab = 0, _generation = 0;
  StreamSubscription<void>? _account;
  @override
  void initState() {
    super.initState();
    _account = LocalDbService().accountChanges.listen((_) {
      if (mounted) {
        _query.clear();
        _load();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _account?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _posts = [];
      _groups = [];
      _error = null;
      _loading = true;
    });
    try {
      final demo = DemoMode.instance.enabled;
      final result = demo
          ? <List<Map<String, dynamic>>>[
              DemoMode.instance.posts,
              CommunityLocalState.instance.groups
                  .map(
                    (g) => <String, dynamic>{
                      'name': g.name,
                      'description': g.description,
                      'member_count': g.members,
                    },
                  )
                  .toList(),
            ]
          : await Future.wait([
              CommunityRepository.pages('/community/posts'),
              CommunityRepository.pages('/community/groups'),
            ]);
      if (!mounted || generation != _generation) return;
      setState(() {
        _posts = demo
            ? result[0]
            : result[0].map(CommunityRepository.post).toList();
        _groups = result[1];
      });
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(
          () =>
              _error = 'Search could not load community content. Please retry.',
        );
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context),
        w = context.cozyColors.wellness,
        q = _query.text.trim().toLowerCase();
    final posts = _posts
        .where(
          (p) =>
              CommunityLocalState.instance.isVisible(p) &&
              '${p['content']} ${p['topic']}'.toLowerCase().contains(q),
        )
        .toList();
    final groups = _groups
        .where(
          (g) => '${g['name']} ${g['description']}'.toLowerCase().contains(q),
        )
        .toList();
    return Scaffold(
      backgroundColor: w.canvas(
        t.brightness,
        MediaQuery.highContrastOf(context),
      ),
      appBar: AppBar(title: const Text('Search community')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(w.page),
          children: [
            TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                labelText: 'Search posts and groups',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            SizedBox(height: w.gap),
            WellnessSegments(
              labels: const ['Posts', 'Groups'],
              selected: _tab,
              keyPrefix: 'search-tab',
              onSelected: (i) => setState(() => _tab = i),
            ),
            SizedBox(height: w.gap),
            if (_loading)
              const LinearProgressIndicator()
            else if (_error != null) ...[
              Text(_error!),
              WellnessAction(label: 'Retry search', onPressed: _load),
            ] else if (q.isEmpty)
              const Text(
                'Type a word or topic to search community posts and groups.',
              )
            else if (_tab == 0) ...[
              if (posts.isEmpty) const Text('No posts match your search.'),
              for (final p in posts)
                Padding(
                  padding: EdgeInsets.only(bottom: w.gap),
                  child: PostCard(
                    post: p,
                    onTap: () =>
                        context.push(AppRouter.postDetail, extra: {'post': p}),
                    onAvatarTap: () {
                      if (p['isAnonymous'] != true) {
                        context.push(
                          AppRouter.userProfile,
                          extra: {
                            'username': p['username'],
                            'authorId': p['authorId'],
                          },
                        );
                      }
                    },
                    onLongPress: () => PostActions.show(context, p),
                  ),
                ),
            ] else ...[
              if (groups.isEmpty) const Text('No groups match your search.'),
              for (final g in groups)
                Padding(
                  padding: EdgeInsets.only(bottom: w.gap),
                  child: WellnessPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${g['name']}', style: t.textTheme.titleMedium),
                        SizedBox(height: w.small),
                        Text('${g['description'] ?? ''}'),
                        SizedBox(height: w.small),
                        Text('${g['member_count'] ?? 0} members'),
                        const Text(
                          'Open Community → Groups to manage membership.',
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

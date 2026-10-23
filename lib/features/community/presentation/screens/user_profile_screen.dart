import '../../../../core/widgets/wellness_sheet.dart';
import '../../../../core/theme/cozy_colors.dart';
import '../../../../core/widgets/wellness_panel.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../data/community_repository.dart';
import '../widgets/post_card.dart';
import '../widgets/post_actions.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key, required this.extra, this.loadPosts});
  final Map<String, dynamic> extra;
  final Future<List<Map<String, dynamic>>> Function(String path)? loadPosts;
  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true, _blocking = false;
  String? _error;
  final _owner = LocalDbService().activeUserId;
  StreamSubscription<void>? _account;
  @override
  void initState() {
    super.initState();
    _account = LocalDbService().accountChanges.listen((_) {
      if (mounted) {
        setState(() {
          _posts = [];
          _error = 'Account changed. Reopen this profile.';
        });
      }
    });
    _load();
  }

  @override
  void dispose() {
    _account?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final id = widget.extra['authorId'];
      if (id == null) throw StateError('Author unavailable');
      final rows = await (widget.loadPosts ?? CommunityRepository.pages)(
        '/community/users/$id/posts',
      );
      if (!mounted || _owner != LocalDbService().activeUserId) return;
      setState(
        () => _posts = rows
            .map(CommunityRepository.post)
            .where((p) => p['isAnonymous'] != true)
            .toList(),
      );
    } catch (_) {
      if (mounted && _owner == LocalDbService().activeUserId) {
        setState(
          () => _error = 'This person’s public posts could not be loaded.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _block() async {
    final confirmed = await confirmWellnessAction(
      context,
      title: 'Block this member?',
      message: 'Their posts will be hidden. You can unblock them in Settings.',
      action: 'Block member',
      cancel: 'Keep member unblocked',
    );
    if (confirmed != true ||
        !mounted ||
        _owner != LocalDbService().activeUserId ||
        widget.extra['authorId']?.toString() == _owner) {
      return;
    }
    setState(() => _blocking = true);
    try {
      await ApiClient().post(
        '/community/users/${widget.extra['authorId']}/block',
      );
      if (!mounted || _owner != LocalDbService().activeUserId) return;
      AppSnackbar.show(context, AppSnackbar.info('User blocked'));
      context.pop();
    } catch (_) {
      if (mounted && _owner == LocalDbService().activeUserId) {
        AppSnackbar.show(
          context,
          AppSnackbar.error('Could not block this person. Please retry.'),
        );
      }
    } finally {
      if (mounted) setState(() => _blocking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.extra['username'] as String? ?? 'Community member';
    final t = Theme.of(context), w = context.cozyColors.wellness;
    return Scaffold(
      backgroundColor: w.canvas(
        t.brightness,
        MediaQuery.highContrastOf(context),
      ),
      appBar: AppBar(title: const Text('Member profile')),
      body: ListView(
        padding: EdgeInsets.all(w.page),
        children: [
          WellnessPanel(
            tinted: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 48,
                  color: wellnessAccentInk(
                    context,
                    background: w.accentPanel(t.colorScheme),
                  ),
                ),
                SizedBox(height: w.contentGap),
                Text(username, style: t.textTheme.headlineSmall),
                SizedBox(height: w.small),
                const Text('Community member'),
              ],
            ),
          ),
          SizedBox(height: w.sectionSpacing),
          Text('Public posts', style: t.textTheme.titleLarge),
          SizedBox(height: w.small),
          const Text('Only public, non-anonymous posts appear here.'),
          SizedBox(height: w.gap),
          if (widget.extra['authorId'] != null &&
              widget.extra['authorId'].toString() != _owner)
            WellnessAction(
              label: _blocking ? 'Blocking…' : 'Block member',
              onPressed: _blocking ? null : _block,
            ),
          SizedBox(height: w.contentGap),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null) ...[
            Text(_error!),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ] else if (_posts.isEmpty)
            const Text('No public posts to show.')
          else
            for (final post in _posts)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: PostCard(
                  post: post,
                  onTap: () =>
                      context.push(AppRouter.postDetail, extra: {'post': post}),
                  onAvatarTap: () {},
                  onLongPress: () => PostActions.show(context, post),
                ),
              ),
        ],
      ),
    );
  }
}

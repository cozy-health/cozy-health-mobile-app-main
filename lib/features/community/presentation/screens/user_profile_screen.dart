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
  const UserProfileScreen({super.key, required this.extra});
  final Map<String, dynamic> extra;
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
      final rows = await CommunityRepository.pages(
        '/community/users/$id/posts',
      );
      if (!mounted || _owner != LocalDbService().activeUserId) return;
      setState(() => _posts = rows.map(CommunityRepository.post).toList());
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'This person’s public posts could not be loaded.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _block() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block this person?'),
        content: const Text(
          'Their posts will be hidden. You can unblock them in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _blocking = true);
    try {
      await ApiClient().post(
        '/community/users/${widget.extra['authorId']}/block',
      );
      if (!mounted || _owner != LocalDbService().activeUserId) return;
      AppSnackbar.show(context, AppSnackbar.info('User blocked'));
      context.pop();
    } catch (_) {
      if (mounted) {
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
    return Scaffold(
      appBar: AppBar(title: Text(username)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Public, non-anonymous posts'),
          const SizedBox(height: 12),
          const Text(
            'Following, private messages and profile links are not available yet. You can report individual posts from their action menu.',
          ),
          if (widget.extra['authorId'] != null)
            OutlinedButton(
              onPressed: _blocking ? null : _block,
              child: Text(_blocking ? 'Blocking…' : 'Block user'),
            ),
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

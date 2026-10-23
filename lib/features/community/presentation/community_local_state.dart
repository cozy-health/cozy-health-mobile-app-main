// TODO: wire to backend when endpoint exists
import 'package:flutter/foundation.dart';
import '../../../core/data/demo_mode.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/widgets/app_snackbar.dart';

class CommunityGroup {
  CommunityGroup({
    required this.id,
    required this.name,
    required this.topic,
    required this.description,
    this.members = 1,
    this.joined = false,
  });
  final String id;
  final String name;
  final String topic;
  final String description;
  final int members;
  bool joined;
}

/// Session-only preview state. No remote persistence or access control is implied.
class CommunityLocalState extends ChangeNotifier {
  void ingestPost(Map<String, dynamic> post) {
    posts.removeWhere((old) => old['id'] == post['id']);
    posts.insert(0, post);
    notifyListeners();
  }

  CommunityLocalState();
  static final instance = CommunityLocalState();
  void clearAccountState() {
    posts.clear();
    _threads.clear();
    _blockedUsers.clear();
    _hiddenPosts.clear();
    groups
      ..clear()
      ..addAll(_defaultGroups());
    _sequence = 0;
    notifyListeners();
  }

  static const topics = [
    'Anxiety',
    'Depression',
    'Trauma',
    'Sleep',
    'Relationships',
    'Self-compassion',
    'Work & Life',
    'Grief & Loss',
    'Work',
    'Self-care',
  ];
  final List<CommunityGroup> groups = _defaultGroups();
  static List<CommunityGroup> _defaultGroups() => [
    CommunityGroup(
      id: 'anxiety',
      name: 'Anxiety Group',
      topic: 'Anxiety',
      members: 100,
      description:
          'A safe space to share experiences and coping strategies for anxiety.',
    ),
    CommunityGroup(
      id: 'suicide',
      name: 'Suicide Group',
      topic: 'Depression',
      members: 500,
      description: 'A space to share experiences and support one another.',
    ),
    CommunityGroup(
      id: 'trauma',
      name: 'Trauma Group',
      topic: 'Trauma',
      members: 500,
      description:
          'A safe space to share experiences and coping strategies for trauma.',
    ),
  ];
  final List<Map<String, dynamic>> posts = [];
  final Set<String> _blockedUsers = {};
  final Set<String> _hiddenPosts = {};

  bool isVisible(Map<String, dynamic> post) =>
      !_hiddenPosts.contains(postKey(post)) &&
      (post['isAnonymous'] == true ||
          !_blockedUsers.contains(post['username']));

  void blockUser(String username) {
    if (username.isNotEmpty) _blockedUsers.add(username);
    notifyListeners();
  }

  void hidePost(Map<String, dynamic> post) {
    _hiddenPosts.add(postKey(post));
    notifyListeners();
  }

  final Map<String, List<Map<String, dynamic>>> _threads = {};
  void replaceThread(
    Map<String, dynamic> post,
    List<Map<String, dynamic>> rows,
  ) {
    _threads[postKey(post)] = rows;
    post['comments'] = rows.length;
    notifyListeners();
  }

  int _sequence = 0;

  void toggleMembership(CommunityGroup group) {
    group.joined = !group.joined;
    notifyListeners();
  }

  CommunityGroup createGroup({
    required String name,
    required String topic,
    required String description,
  }) {
    final group = CommunityGroup(
      id: 'local-group-${++_sequence}',
      name: name.trim(),
      topic: topic,
      description: description.trim(),
      joined: true,
    );
    groups.add(group);
    notifyListeners();
    return group;
  }

  void publish({
    required String content,
    required String topic,
    required String visibility,
  }) {
    (DemoMode.instance.enabled ? DemoMode.instance.posts : posts).insert(0, {
      'id': 'local-post-${++_sequence}',
      'username': 'you',
      'isAnonymous': visibility == 'anonymous',
      'visibility': visibility,
      'timeAgo': 'Just now',
      'content': content,
      'topic': topic,
      'likes': 0,
      'comments': 0,
      'isLiked': false,
    });
    notifyListeners();
  }

  String postKey(Map<String, dynamic> post) =>
      post['id']?.toString() ??
      '${post['username']}|${post['content']}|${post['timeAgo']}';

  List<Map<String, dynamic>> thread(
    Map<String, dynamic> post,
    List<Map<String, dynamic>> initial,
  ) => _threads.putIfAbsent(
    postKey(post),
    () => initial.map((comment) => Map<String, dynamic>.from(comment)).toList(),
  );

  void addComment(
    Map<String, dynamic> post,
    List<Map<String, dynamic>> comments,
    String content, {
    Map<String, dynamic>? parent,
  }) {
    final comment = <String, dynamic>{
      'id': 'local-comment-${++_sequence}',
      'username': 'you',
      'isAnonymous': false,
      'timeAgo': 'Just now',
      'content': content.trim(),
      'likes': 0,
      'isLiked': false,
    };
    if (parent == null) {
      comments.add(comment);
    } else {
      (parent.putIfAbsent('replies', () => <Map<String, dynamic>>[]) as List)
          .add(comment);
    }
    post['comments'] = (post['comments'] as int? ?? 0) + 1;
    notifyListeners();
  }

  Future<void> toggleLike(Map<String, dynamic> item) async {
    final liked = item['isLiked'] as bool? ?? false;
    if (!DemoMode.instance.enabled) {
      final owner = LocalDbService().activeUserId;
      try {
        final response = await ApiClient().put(
          '/community/${item['kind'] ?? 'posts'}/${item['id']}/reaction',
          data: {'liked': !liked},
        );
        if (owner != LocalDbService().activeUserId) return;
        item['isLiked'] = response.data['data']['liked'];
        item['likes'] = response.data['data']['count'];
        notifyListeners();
      } catch (_) {
        final context = AppRouter.navigatorKey.currentContext;
        if (context != null && context.mounted) {
          AppSnackbar.show(
            context,
            AppSnackbar.error('Could not update your reaction. Please retry.'),
          );
        }
      }
      return;
    }
    item['isLiked'] = !liked;
    item['likes'] = ((item['likes'] as int? ?? 0) + (liked ? -1 : 1)).clamp(
      0,
      1 << 30,
    );
    notifyListeners();
  }
}

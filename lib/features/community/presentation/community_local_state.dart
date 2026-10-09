// TODO: wire to backend when endpoint exists
import 'package:flutter/foundation.dart';

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
  CommunityLocalState();
  static final instance = CommunityLocalState();
  static const topics = [
    'Anxiety',
    'Depression',
    'Trauma',
    'Sleep',
    'Relationships',
    'Self-compassion',
    'Work & Life',
    'Grief & Loss',
  ];
  final List<CommunityGroup> groups = [
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
  final Map<String, List<Map<String, dynamic>>> _threads = {};
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
    posts.insert(0, {
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

  void toggleLike(Map<String, dynamic> item) {
    final liked = item['isLiked'] as bool? ?? false;
    item['isLiked'] = !liked;
    item['likes'] = ((item['likes'] as int? ?? 0) + (liked ? -1 : 1)).clamp(
      0,
      1 << 30,
    );
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../../core/api/api_client.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/data/demo_mode.dart';
import '../presentation/community_local_state.dart';
import '../../../core/storage/token_storage.dart';

/// Live API data in normal mode; sample activity is confined to demo mode.
class CommunityRepository extends ChangeNotifier {
  CommunityRepository({bool? usePlaceholderData})
    : _placeholderOverride = usePlaceholderData {
    CommunityLocalState.instance.addListener(_refresh);
    DemoMode.instance.addListener(_refresh);
    _owner = LocalDbService().activeUserId;
    _account = LocalDbService().accountChanges.listen((_) {
      final owner = LocalDbService().activeUserId;
      if (owner == _owner) return;
      _owner = owner;
      _epoch++;
      loading = false;
      error = null;
      CommunityLocalState.instance.clearAccountState();
      if (!_disposed) _refresh();
    });
    if (!this.usePlaceholderData) unawaited(load());
  }
  StreamSubscription<void>? _account;
  String? _owner;
  int _epoch = 0;
  bool _disposed = false, loading = false;
  String? error;
  static Map<String, dynamic> post(Map row) => {
    'id': row['id'],
    'parentId': row['parent_id'],
    'username': row['author']?['name'] ?? 'Community member',
    'authorId': row['author']?['id'],
    'isAnonymous': row['is_anonymous'] == true,
    'content': row['body'] ?? '',
    'imageUrl': row['image_url'],
    'timeAgo': row['created_at'] ?? '',
    'topic': row['mood'] ?? '',
    'comments': row['comment_count'] ?? 0,
    'likes': row['like_count'] ?? 0,
    'isLiked': row['is_liked'] == true,
    'isOwner': row['is_owner'] == true,
    'status': row['status'],
    'kind': row.containsKey('post_id') ? 'comments' : 'posts',
  };
  static Future<List<Map<String, dynamic>>> pages(String path) async {
    final generation = TokenStorage.generation;
    final owner = LocalDbService().activeUserId;
    final result = <Map<String, dynamic>>[];
    var page = 1, last = 1;
    do {
      final response = await ApiClient().get(
        path,
        query: {'page': page, 'per_page': 50},
      );
      if (owner != LocalDbService().activeUserId ||
          generation != TokenStorage.generation) {
        throw StateError('Account changed');
      }
      final data = response.data['data'] as Map;
      result.addAll(
        (data['data'] as List).map(
          (row) => Map<String, dynamic>.from(row as Map),
        ),
      );
      last = (data['last_page'] as num).toInt();
      if (last < page || last > 1000) {
        throw const FormatException('Invalid pages');
      }
      page++;
    } while (page <= last);
    return result;
  }

  Future<void> load() async {
    if (_disposed || loading || usePlaceholderData) return;
    loading = true;
    final epoch = _epoch;
    error = null;
    try {
      final rows = await pages('/community/posts');
      if (_disposed || epoch != _epoch) return;
      CommunityLocalState.instance.posts
        ..clear()
        ..addAll(rows.map(post));
    } catch (_) {
      if (!_disposed && epoch == _epoch) {
        error = 'Community could not be loaded. It may not be available yet.';
      }
    } finally {
      if (!_disposed && epoch == _epoch) {
        loading = false;
        notifyListeners();
      }
    }
  }

  final bool? _placeholderOverride;
  bool get usePlaceholderData =>
      _placeholderOverride ?? DemoMode.instance.enabled;
  List<Map<String, dynamic>> get posts => usePlaceholderData
      ? DemoMode.instance.posts
      : CommunityLocalState.instance.posts;
  void _refresh() {
    if (_disposed) return;
    if (!usePlaceholderData) {
      unawaited(load());
    } else {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _account?.cancel();
    CommunityLocalState.instance.removeListener(_refresh);
    DemoMode.instance.removeListener(_refresh);
    super.dispose();
  }
}

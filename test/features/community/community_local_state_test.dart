import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/features/community/presentation/community_local_state.dart';

void main() {
  late CommunityLocalState state;
  setUp(() => state = CommunityLocalState());
  tearDown(() => state.dispose());
  test('joining and leaving retain the same group', () {
    final group = state.groups.first;
    state.toggleMembership(group);
    expect(group.joined, isTrue);
    state.toggleMembership(group);
    expect(group.joined, isFalse);
    expect(state.groups.length, 3);
  });
  test('creating a group saves its topic and joins it', () {
    final group = state.createGroup(
      name: ' Test ',
      topic: 'Sleep',
      description: ' Rest ',
    );
    expect(group.name, 'Test');
    expect(group.description, 'Rest');
    expect(group.topic, 'Sleep');
    expect(group.joined, isTrue);
    expect(state.groups.last, same(group));
  });
  test('post category and anonymous visibility survive publishing', () {
    state.publish(content: 'Hello', topic: 'Anxiety', visibility: 'anonymous');
    expect(state.posts.single['topic'], 'Anxiety');
    expect(state.posts.single['isAnonymous'], isTrue);
    expect(state.posts.single['visibility'], 'anonymous');
  });
  test('new posts have unique IDs and appear first', () {
    state.publish(content: 'First', topic: '', visibility: 'public');
    state.publish(content: 'Second', topic: 'Sleep', visibility: 'followers');
    expect(state.posts.first['content'], 'Second');
    expect(state.posts.map((post) => post['id']).toSet().length, 2);
  });
  test('comment threads persist while reopening and remain isolated', () {
    final first = <String, dynamic>{'id': 'first'};
    final second = <String, dynamic>{'id': 'second'};
    final comments = state.thread(first, []);
    state.addComment(first, comments, ' Comment ');
    expect(state.thread(first, []).single['content'], 'Comment');
    expect(state.thread(second, []), isEmpty);
    expect(first['comments'], 1);
  });
  test('replies are nested under the selected comment', () {
    final post = <String, dynamic>{'id': 'post'};
    final comments = state.thread(post, []);
    state.addComment(post, comments, 'Parent');
    state.addComment(post, comments, 'Reply', parent: comments.first);
    expect(comments.length, 1);
    expect((comments.first['replies'] as List).single['content'], 'Reply');
    expect(post['comments'], 2);
  });
  test('likes toggle without creating negative counts', () {
    final post = <String, dynamic>{'likes': 0, 'isLiked': false};
    state.toggleLike(post);
    expect(post['likes'], 1);
    state.toggleLike(post);
    expect(post['likes'], 0);
    expect(post['isLiked'], isFalse);
  });
}

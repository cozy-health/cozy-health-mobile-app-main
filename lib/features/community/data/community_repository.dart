import 'package:flutter/foundation.dart';
import '../../../core/data/demo_mode.dart';
import '../presentation/community_local_state.dart';

/// Community currently uses session-local state until its API is available.
class CommunityRepository extends ChangeNotifier {
  CommunityRepository({bool? usePlaceholderData})
    : _placeholderOverride = usePlaceholderData {
    CommunityLocalState.instance.addListener(_refresh);
    DemoMode.instance.addListener(_refresh);
  }
  final bool? _placeholderOverride;
  bool get usePlaceholderData =>
      _placeholderOverride ?? DemoMode.instance.enabled;
  List<Map<String, dynamic>> get posts => usePlaceholderData
      ? DemoMode.instance.posts
      : CommunityLocalState.instance.posts;
  void _refresh() => notifyListeners();
  @override
  void dispose() {
    CommunityLocalState.instance.removeListener(_refresh);
    DemoMode.instance.removeListener(_refresh);
    super.dispose();
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../models/user_preferences.dart';
import '../storage/token_storage.dart';
import 'local_db_service.dart';
import 'user_data_merge.dart';

typedef RestoreGet =
    Future<dynamic> Function(String path, Map<String, dynamic> query);

class RestoreService {
  static Future<bool> prepare(
    String userId, {
    bool registration = false,
  }) async {
    final local = LocalDbService();
    final settings = await local.settingsBox();
    await settings.put('device_user_id', userId);
    final incomplete = settings.get('restore_incomplete_user') == userId;
    final hasHistory = [
      LocalDbService.moodBoxName,
      LocalDbService.journalBoxName,
      LocalDbService.chatConversationBoxName,
      LocalDbService.quizAttemptBoxName,
      LocalDbService.safetyPlanBoxName,
      LocalDbService.savedArticleBoxName,
    ].any((name) => local.isBoxOpen(name) && _hasRecords(name));
    final required =
        !registration &&
        (incomplete ||
            (settings.get('restored_user_id') != userId && !hasHistory));
    await settings.put('restore_requested', required);
    if (required) {
      await settings.put('restore_incomplete_user', userId);
    } else {
      await settings.putAll({
        'has_restored_on_device': true,
        'restored_user_id': userId,
      });
    }
    return required;
  }

  static bool _hasRecords(String name) => switch (name) {
    LocalDbService.moodBoxName => LocalDbService().moodBox.isNotEmpty,
    LocalDbService.journalBoxName => LocalDbService().journalBox.isNotEmpty,
    LocalDbService.chatConversationBoxName =>
      LocalDbService().chatConversationBox.isNotEmpty,
    LocalDbService.quizAttemptBoxName =>
      LocalDbService().quizAttemptBox.isNotEmpty,
    LocalDbService.safetyPlanBoxName =>
      LocalDbService().safetyPlanBox.isNotEmpty,
    LocalDbService.savedArticleBoxName =>
      LocalDbService().savedArticleBox.isNotEmpty,
    _ => false,
  };
  static Future<bool> get required async =>
      (await LocalDbService().settingsBox()).get('restore_requested') == true;
}

class RestoreController extends ChangeNotifier {
  RestoreController({required this.userId, RestoreGet? get, DateTime? now})
    : _get = get ?? _apiGet,
      _cutoff = (now ?? DateTime.now()).toUtc().subtract(
        const Duration(days: 90),
      );
  final String userId;
  final RestoreGet _get;
  final DateTime _cutoff;
  final _merge = UserDataMerge();
  final _completed = <String>{};
  final failed = <String>{};
  final unavailable = <String>{};
  final _seen = <String>{};
  Map<String, dynamic>? _profile;
  bool busy = false;
  bool cancelled = false;
  bool _disposed = false;
  String current = 'User profile';
  int get restored => _seen.length;
  double get progress => _completed.length / steps.length;
  static const steps = [
    'User profile',
    'User preferences',
    'Safety plan',
    'Emergency contacts',
    'Mood entries',
    'Journal entries',
    'Quiz attempts',
    'Saved articles',
    'Notifications',
    'Conversations',
  ];
  static Future<dynamic> _apiGet(
    String path,
    Map<String, dynamic> query,
  ) async => (await ApiClient.instance.get(path, queryParameters: query)).data;
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  bool get _active => !cancelled && !_disposed;
  Future<bool> _sameOwner() async =>
      _active &&
      (await LocalDbService().settingsBox()).get('device_user_id') == userId;

  Future<void> run({bool retryOnly = false}) async {
    if (busy || cancelled) return;
    busy = true;
    _changed();
    final todo = retryOnly
        ? steps.where(failed.contains).toList()
        : steps.where((step) => !_completed.contains(step)).toList();
    if (retryOnly &&
        (todo.contains('User profile') || todo.contains('User preferences'))) {
      _profile = null;
    }
    for (final step in todo) {
      if (!await _sameOwner()) break;
      current = step;
      _changed();
      try {
        await _fetchStep(step);
        if (!await _sameOwner()) break;
        _completed.add(step);
        failed.remove(step);
      } catch (_) {
        if (_active) failed.add(step);
      }
      _changed();
    }
    busy = false;
    _changed();
  }

  Future<Map<String, dynamic>> _profileData() async {
    if (_profile != null) return _profile!;
    final data = _single(await _get('/user/profile', {}));
    if (data == null) throw const FormatException('Missing profile');
    _profile = data;
    return data;
  }

  Future<void> _fetchStep(String step) async {
    switch (step) {
      case 'User profile':
        final profile = await _profileData();
        if (!await _sameOwner()) return;
        await _merge.apply(
          'user_profile',
          profile,
          owner: userId,
          isActive: () => _active,
        );
        _seen.add('profile');
      case 'User preferences':
        final data = (await _profileData())['preferences'];
        if (data is Map && data.isNotEmpty && await _sameOwner()) {
          final value = UserPreferences.fromJson(
            Map<String, dynamic>.from(data),
          );
          final local = await LocalDbService().getUserPreferences();
          final pending = LocalDbService().pendingItems
              .where((item) => item.type == 'user_preferences')
              .toList();
          if (local == null || value.completedAt.isAfter(local.completedAt)) {
            for (final item in pending) {
              await LocalDbService().syncQueueBox.delete(item.id);
            }
            await (await LocalDbService().preferencesBox()).put(
              'current',
              value,
            );
            await (await LocalDbService().settingsBox()).put(
              'onboarding_preferences',
              value.toJson(),
            );
          } else if (local.completedAt.isAfter(value.completedAt) &&
              pending.isEmpty) {
            await LocalDbService().saveUserPreferences(local);
          }
          _seen.add('preferences');
        }
      case 'Safety plan':
        try {
          final plan = _single(await _get('/safety-plan', {}));
          if (plan != null && await _sameOwner()) {
            await _merge.apply(
              'safety_plan',
              plan,
              owner: userId,
              isActive: () => _active,
            );
            _seen.add('safety_plan');
          }
        } on ApiException catch (error) {
          if (error.statusCode != 404) rethrow;
        }
      case 'Emergency contacts':
        // No standalone endpoint exists. Recover contacts carried by the plan.
        unavailable.add('Standalone emergency contacts');
        if (failed.contains('Safety plan')) {
          throw StateError('Safety plan unavailable');
        }
        final people = LocalDbService().getSafetyPlan()?.peopleToCall ?? [];
        if (await _sameOwner()) {
          await (await LocalDbService().settingsBox()).put(
            'restored_emergency_contacts',
            people,
          );
          for (var i = 0; i < people.length; i++) {
            _seen.add('contact:$i');
          }
        }
      case 'Mood entries':
        await _list('/mood-entries', 'mood_entry', recent: true);
      case 'Journal entries':
        await _list('/journal-entries', 'journal_entry', recent: true);
      case 'Quiz attempts':
        await _list('/quiz-attempts', 'quiz_attempt');
      case 'Saved articles':
        await _list('/content/saved', 'saved_article');
      case 'Notifications':
        await _list('/notifications', 'app_notification');
      case 'Conversations':
        await _list('/conversations', 'chat_conversation');
    }
  }

  Future<void> _list(
    String endpoint,
    String type, {
    bool recent = false,
  }) async {
    var page = 1;
    var lastPage = 1;
    do {
      final response = await _get(endpoint, {'page': page, 'per_page': 50});
      if (!await _sameOwner()) return;
      final payload = response is Map ? response['data'] ?? response : response;
      final rows = payload is Map ? payload['data'] : payload;
      if (rows is! List) throw const FormatException('Invalid list response');
      final last = payload is Map ? payload['last_page'] : null;
      lastPage = last is num ? last.toInt() : 1;
      if (lastPage < page || lastPage > 1000) {
        throw const FormatException('Invalid pagination');
      }
      var recentRows = 0;
      for (final raw in rows) {
        if (!await _sameOwner()) return;
        if (raw is! Map) throw const FormatException('Invalid record');
        final row = Map<String, dynamic>.from(raw);
        final created = DateTime.tryParse(
          (row['client_created_at'] ?? row['created_at'])?.toString() ?? '',
        );
        if (recent && created != null && created.toUtc().isBefore(_cutoff)) {
          continue;
        }
        recentRows++;
        await _merge.apply(type, row, owner: userId, isActive: () => _active);
        _seen.add('$type:${row['id']}');
        _changed();
      }
      // Both history endpoints are ordered by client_created_at descending.
      if (recent && rows.isNotEmpty && recentRows == 0) break;
      page++;
    } while (page <= lastPage && _active);
  }

  static Map<String, dynamic>? _single(dynamic response) {
    final value = response is Map ? response['data'] ?? response : response;
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  Future<void> finish({bool acceptPartial = false}) async {
    if (busy ||
        _completed.length + failed.length < steps.length ||
        (!acceptPartial && failed.isNotEmpty) ||
        !await _sameOwner()) {
      return;
    }
    final settings = await LocalDbService().settingsBox();
    await settings.putAll({
      'has_restored_on_device': failed.isEmpty,
      'restored_user_id': failed.isEmpty ? userId : null,
      'restore_requested': false,
      'restore_unavailable': unavailable.toList(),
    });
    if (failed.isEmpty) await settings.delete('restore_incomplete_user');
    unawaited(LocalDbService().processSyncQueue());
  }

  Future<void> cancel() async {
    cancelled = true;
    _changed();
    await (await LocalDbService().settingsBox()).put(
      'restore_requested',
      false,
    );
    await TokenStorage().clearToken();
    await LocalDbService().activateGuest();
  }

  @override
  void dispose() {
    _disposed = true;
    cancelled = true;
    super.dispose();
  }
}

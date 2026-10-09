import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../storage/token_storage.dart';

typedef ConsentGet = Future<Map<String, dynamic>> Function(String path);
typedef ConsentPost =
    Future<Map<String, dynamic>> Function(Map<String, dynamic> body);

class ConsentDocument {
  ConsentDocument(this.type, Map<String, dynamic> json)
    : title = json['title'] as String,
      version = json['version'] as String,
      published = json['published'] == true,
      required = json['required'] == true && type != 'marketing',
      content = json['content'] as String?;
  final String type, title, version;
  final bool published, required;
  final String? content;
  bool get reviewable =>
      published &&
      !version.startsWith('draft-') &&
      (content?.trim().isNotEmpty ?? false);
}

class ConsentState {
  ConsentState({
    required this.ownerId,
    required this.documents,
    required this.records,
    required this.enforceBlocking,
  });
  final int ownerId;
  final List<ConsentDocument> documents;
  final List<Map<String, dynamic>> records;
  final bool enforceBlocking;
  bool current(ConsentDocument doc) => records.any(
    (record) =>
        record['document_type'] == doc.type &&
        record['version'] == doc.version &&
        (record['status'] == 'accepted' ||
            (doc.type != 'marketing' && !doc.published && record['status'] == 'pre_acceptance')),
  );
  List<ConsentDocument> get pending => documents
      .where((doc) => doc.type != 'marketing' && !current(doc))
      .toList();
  bool blocking(ConsentDocument doc) =>
      enforceBlocking && doc.required && doc.reviewable;
  bool get marketingAllowed =>
      documents.where((doc) => doc.type == 'marketing').any(current);
}

class ConsentService {
  ConsentService({
    ConsentGet? get,
    ConsentPost? post,
    Future<String?> Function()? token,
  }) : _get = get ?? _getApi,
       _post = post ?? _postApi,
       _token = token ?? TokenStorage().getToken;
  final ConsentGet _get;
  final ConsentPost _post;
  final Future<String?> Function() _token;
  String? _loadedToken;

  static Map<String, dynamic> _map(dynamic response) =>
      Map<String, dynamic>.from(
        response is Response ? response.data : response,
      );
  static Future<Map<String, dynamic>> _getApi(String path) async =>
      _map(await ApiClient().get(path, withAuth: path != '/config'));
  static Future<Map<String, dynamic>> _postApi(
    Map<String, dynamic> body,
  ) async => _map(await ApiClient().post('/me/consents', data: body));

  Future<ConsentState?> load() async {
    final token = await _token();
    if (token == null) return null;
    final config = (await _get('/config'))['consent'] as Map;
    final response = await _get('/me/consents');
    if (await _token() != token) return null;
    _loadedToken = token;
    final state = ConsentState(
      ownerId: response['owner_id'] as int,
      documents: (config['documents'] as Map).entries
          .map(
            (entry) => ConsentDocument(
              entry.key as String,
              Map<String, dynamic>.from(entry.value),
            ),
          )
          .toList(),
      records: (response['data'] as List)
          .map((record) => Map<String, dynamic>.from(record))
          .toList(),
      enforceBlocking: config['enforce_blocking'] == true,
    );
    for (final doc in state.pending.toList()) {
      final hasHistory = state.records.any(
        (record) => record['document_type'] == doc.type,
      );
      if (!doc.published && !hasHistory) {
        final record = await _record(
          state,
          doc,
          accepted: false,
          preAcceptance: true,
        );
        state.records.add(record);
      }
    }
    return state;
  }

  Future<Map<String, dynamic>> _record(
    ConsentState state,
    ConsentDocument doc, {
    required bool accepted,
    bool preAcceptance = false,
  }) async {
    if (_loadedToken == null || await _token() != _loadedToken) {
      throw StateError('Your account changed. Review again.');
    }
    final response = await _post({
      'document_type': doc.type,
      'version': doc.version,
      'accepted': accepted,
      'pre_acceptance': preAcceptance,
      'actor_id': state.ownerId,
    });
    if (await _token() != _loadedToken ||
        response['owner_id'] != state.ownerId) {
      throw StateError('Your account changed. Review again.');
    }
    return Map<String, dynamic>.from(response['data']);
  }

  Future<void> accept(ConsentState state, ConsentDocument doc) async {
    if (!doc.reviewable) {
      throw StateError('This document is not published yet.');
    }
    await _save(state, doc, true);
  }

  Future<void> marketing(ConsentState state, bool enabled) async => _save(
    state,
    state.documents.firstWhere((doc) => doc.type == 'marketing'),
    enabled,
  );

  Future<void> _save(
    ConsentState state,
    ConsentDocument doc,
    bool accepted,
  ) async {
    final record = await _record(state, doc, accepted: accepted);
    state.records.removeWhere(
      (row) =>
          row['document_type'] == doc.type && row['version'] == doc.version,
    );
    state.records.add(record);
  }
}

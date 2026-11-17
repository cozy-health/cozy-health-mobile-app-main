import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/local_db_service.dart';
import '../../../core/storage/token_storage.dart';

typedef OperationsGet =
    Future<dynamic> Function(
      String path, {
      Map<String, dynamic>? queryParameters,
    });
typedef OperationsPost =
    Future<dynamic> Function(String path, {dynamic data, Options? options});

Map<String, dynamic> _object(dynamic value) {
  if (value is! Map) {
    throw const FormatException('The server response was incomplete.');
  }
  return Map<String, dynamic>.from(value);
}

String _text(Map<String, dynamic> row, String key) {
  final value = row[key];
  if (value is! String) {
    throw const FormatException('The server response was incomplete.');
  }
  return value;
}

class OperationsPage<T> {
  const OperationsPage(this.items, this.lastPage);
  final List<T> items;
  final int lastPage;
}

class SupportReply {
  SupportReply.fromJson(Map<String, dynamic> row)
    : id = _text(row, 'id'),
      author = _text(row, 'author'),
      body = _text(row, 'body');
  final String id, author, body;
}

class SupportCase {
  SupportCase.fromJson(Map<String, dynamic> row)
    : id = (row['id'] as num).toInt(),
      subject = _text(row, 'subject'),
      status = _text(row, 'status'),
      message = row['message'] as String? ?? '',
      version = row['version'] as int? ?? 0,
      messages = (row['messages'] as List? ?? [])
          .map((value) => SupportReply.fromJson(_object(value)))
          .toList();
  final int id, version;
  final String subject, status, message;
  final List<SupportReply> messages;
}

class CustomerPrivacyRequest {
  CustomerPrivacyRequest.fromJson(Map<String, dynamic> row)
    : id = _text(row, 'id'),
      kind = _text(row, 'kind'),
      status = _text(row, 'status'),
      outcome = row['outcome'] as String?;
  final String id, kind, status;
  final String? outcome;
}

/// No second cache/outbox: private requests use existing session-bound transport.
class CustomerOperations {
  CustomerOperations({
    OperationsGet? get,
    OperationsPost? post,
    String? Function()? account,
    int Function()? generation,
  }) : _get = get ?? ApiClient().get,
       _post = post ?? ApiClient().post,
       _account = account ?? (() => LocalDbService().activeUserId),
       _generation = generation ?? (() => TokenStorage.generation) {
    _owner = _account();
    _session = _generation();
  }
  final OperationsGet _get;
  final OperationsPost _post;
  final String? Function() _account;
  final int Function() _generation;
  late final String? _owner;
  late final int _session;
  bool get current {
    final owner = _owner;
    return owner != null &&
        !owner.startsWith('guest_') &&
        owner == _account() &&
        _session == _generation();
  }

  void _check() {
    if (!current) throw StateError('Sign in again to access your requests.');
  }

  Map<String, dynamic> _data(dynamic response) =>
      _object(_object(response.data)['data']);
  Future<OperationsPage<T>> _list<T>(
    String path,
    int page,
    T Function(Map<String, dynamic>) parse,
  ) async {
    _check();
    final response = await _get(path, queryParameters: {'page': page});
    _check();
    final data = _data(response), rows = data['data'];
    if (rows is! List || data['last_page'] is! int) {
      throw const FormatException('The server response was incomplete.');
    }
    return OperationsPage(
      rows.map((row) => parse(_object(row))).toList(),
      data['last_page'] as int,
    );
  }

  Future<OperationsPage<SupportCase>> support(int page) =>
      _list('/support/reports', page, SupportCase.fromJson);
  Future<SupportCase> conversation(int id) async {
    _check();
    final response = await _get('/support/reports/$id');
    _check();
    return SupportCase.fromJson(_data(response));
  }

  Future<SupportCase> reply(
    int id,
    int version,
    String body,
    String requestId,
  ) async {
    _check();
    final response = await _post(
      '/support/reports/$id/replies',
      data: {
        'body': body,
        'expected_version': version,
        'request_id': requestId,
      },
    );
    _check();
    return SupportCase.fromJson(_data(response));
  }

  Future<OperationsPage<CustomerPrivacyRequest>> privacy(int page) =>
      _list('/privacy-requests', page, CustomerPrivacyRequest.fromJson);
  Future<void> requestPrivacy({
    required String kind,
    required String password,
    required String requestId,
    Map<String, dynamic>? changes,
  }) async {
    _check();
    await _post(
      '/privacy-requests',
      data: {
        'kind': kind,
        'password': password,
        'confirmed': true,
        'request_id': requestId,
        if (changes != null) 'changes': changes,
      },
    );
    _check();
  }

  Future<Uint8List> download(String id, String password) async {
    _check();
    final response = await _post(
      '/privacy-requests/$id/download',
      data: {'password': password},
      options: Options(responseType: ResponseType.bytes),
    );
    _check();
    final bytes = response.data;
    if (bytes is! List<int>) {
      throw const FormatException('The export could not be downloaded.');
    }
    return Uint8List.fromList(bytes);
  }
}

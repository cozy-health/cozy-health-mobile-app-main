import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'consent_service.dart';

/// Dismissing an optional notice never records legal acceptance.
class LegalNoticePreferences {
  const LegalNoticePreferences();
  static const _storage = FlutterSecureStorage();

  static String noticeId(ConsentDocument document) =>
      '${document.type}:${document.version}';

  String _key(int owner, ConsentDocument document) =>
      'cozy_legal_notice_v1_${owner}_${noticeId(document)}';

  Future<Set<String>> dismissed(ConsentState state) async {
    final result = <String>{};
    for (final document in state.updates) {
      if (await _storage.read(key: _key(state.ownerId, document)) ==
          'dismissed') {
        result.add(noticeId(document));
      }
    }
    return result;
  }

  Future<void> dismiss(int owner, ConsentDocument document) =>
      _storage.write(key: _key(owner, document), value: 'dismissed');
}

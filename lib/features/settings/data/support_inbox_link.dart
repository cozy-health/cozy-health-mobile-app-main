import '../../../core/constants/api_constants.dart';

class SupportInboxLink {
  static bool accepts(Uri uri) {
    if (uri.hasQuery || uri.hasFragment || uri.userInfo.isNotEmpty) {
      return false;
    }
    if (uri.scheme == 'cozyhealth') {
      return uri.host == 'support-inbox' && uri.path.isEmpty && !uri.hasPort;
    }
    final api = Uri.parse(ApiConstants.baseUrl);
    return uri.scheme == 'https' &&
        uri.host == api.host &&
        uri.port == api.port &&
        uri.path == '/support-inbox';
  }
}

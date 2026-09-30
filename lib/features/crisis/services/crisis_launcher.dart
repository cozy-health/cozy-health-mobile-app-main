import 'package:url_launcher/url_launcher.dart';

enum LaunchResult { success, noApp, invalidNumber, unknown }

class CrisisLauncher {
  const CrisisLauncher();

  Future<LaunchResult> callPhone(String number) async {
    final sanitized = _sanitizeNumber(number);
    if (sanitized == null) return LaunchResult.invalidNumber;

    final uri = Uri(scheme: 'tel', path: sanitized);
    return _launchWithFallback(
      uri,
      fallbackMode: LaunchMode.externalApplication,
    );
  }

  Future<LaunchResult> sendSms(String number, {String? body}) async {
    final sanitized = _sanitizeNumber(number);
    if (sanitized == null) return LaunchResult.invalidNumber;

    final uri = Uri(
      scheme: 'sms',
      path: sanitized,
      queryParameters: body == null || body.isEmpty ? null : {'body': body},
    );
    final result = await _launchWithFallback(uri);
    if (result == LaunchResult.success || body == null || body.isEmpty) {
      return result;
    }

    return _launchWithFallback(Uri(scheme: 'sms', path: sanitized));
  }

  Future<LaunchResult> sendEmail(
    String address, {
    String? subject,
    String? body,
  }) async {
    if (!address.contains('@')) return LaunchResult.invalidNumber;

    final uri = Uri(
      scheme: 'mailto',
      path: address.trim(),
      queryParameters: {
        if (subject != null && subject.isNotEmpty) 'subject': subject,
        if (body != null && body.isNotEmpty) 'body': body,
      },
    );
    final result = await _launchWithFallback(uri);
    if (result == LaunchResult.success) return result;
    return _launchWithFallback(Uri(scheme: 'mailto', path: address.trim()));
  }

  Future<LaunchResult> openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return LaunchResult.invalidNumber;
    return _launchWithFallback(
      uri,
      fallbackMode: LaunchMode.externalApplication,
    );
  }

  Future<LaunchResult> _launchWithFallback(
    Uri uri, {
    LaunchMode? fallbackMode,
  }) async {
    try {
      if (!await canLaunchUrl(uri)) return LaunchResult.noApp;
      if (await launchUrl(uri)) return LaunchResult.success;
      if (fallbackMode != null && await launchUrl(uri, mode: fallbackMode)) {
        return LaunchResult.success;
      }
      return LaunchResult.unknown;
    } catch (_) {
      return LaunchResult.unknown;
    }
  }

  String? _sanitizeNumber(String number) {
    final trimmed = number.trim();
    if (trimmed.isEmpty) return null;
    final sanitized = trimmed.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    if (!RegExp(r'^\+?\d{2,15}$').hasMatch(sanitized)) return null;
    return sanitized;
  }
}

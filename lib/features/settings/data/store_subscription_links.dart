import 'package:url_launcher/url_launcher.dart';

class StoreSubscriptionLinks {
  static Uri? manage(String? platform) => switch (platform) {
    'apple' => Uri.parse('https://apps.apple.com/account/subscriptions'),
    'google' => Uri.parse(
      'https://play.google.com/store/account/subscriptions',
    ),
    _ => null,
  };

  static Uri? history(String? platform) => switch (platform) {
    'apple' => Uri.parse('https://reportaproblem.apple.com/'),
    'google' => Uri.parse('https://play.google.com/store/account/orderhistory'),
    _ => null,
  };

  static Future<bool> open(Uri uri) async {
    final allowed = [
      'apple',
      'google',
    ].any((platform) => uri == manage(platform) || uri == history(platform));
    if (!allowed) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

import 'dart:convert';
import '../constants/api_constants.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalDocuments {
  static Future<List<Map<String, dynamic>>> load() async {
    final manifest =
        jsonDecode(await rootBundle.loadString('assets/legal/documents.json'))
            as Map<String, dynamic>;
    return (manifest['documents'] as List)
        .map((doc) => Map<String, dynamic>.from(doc as Map))
        .toList();
  }

  static Uri? trustedUrl(String? value) {
    final uri = Uri.tryParse(value ?? '');
    return uri != null &&
            uri.scheme == 'https' &&
            (uri.host == 'cozyhealth.org' ||
                uri.host == 'dev.cozyhealth.org') &&
            uri.userInfo.isEmpty &&
            !uri.hasPort
        ? uri
        : null;
  }

  static String? documentUrl(String? route) {
    if (route == null || !route.startsWith('/') || route.startsWith('//')) {
      return null;
    }
    final host = ApiConstants.environment == 'production'
        ? 'cozyhealth.org'
        : 'dev.cozyhealth.org';
    final uri = Uri.https(host).resolve(route);
    return uri.host == host && trustedUrl(uri.toString()) != null
        ? uri.toString()
        : null;
  }

  static Future<bool> open(String? value) async {
    final uri = trustedUrl(value);
    return uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

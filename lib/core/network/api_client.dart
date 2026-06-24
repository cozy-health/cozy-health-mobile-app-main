import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

class ApiClient {
  final TokenStorage _tokenStorage;

  ApiClient({
    TokenStorage? tokenStorage,
  }) : _tokenStorage = tokenStorage ?? TokenStorage();

  Future<Map<String, String>> _headers({
    bool withAuth = true,
  }) async {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (withAuth) {
      final token = await _tokenStorage.getToken();

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    return Uri.parse('${ApiConstants.baseUrl}$path').replace(
      queryParameters: query?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    bool withAuth = true,
  }) async {
    final response = await http.get(
      _uri(path, query),
      headers: await _headers(withAuth: withAuth),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    final response = await http.post(
      _uri(path),
      headers: await _headers(withAuth: withAuth),
      body: jsonEncode(body ?? {}),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    final response = await http.put(
      _uri(path),
      headers: await _headers(withAuth: withAuth),
      body: jsonEncode(body ?? {}),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    bool withAuth = true,
  }) async {
    final response = await http.delete(
      _uri(path),
      headers: await _headers(withAuth: withAuth),
    );

    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final decoded = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : <String, dynamic>{};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) return decoded;

      return {
        'success': true,
        'data': decoded,
      };
    }

    String message = 'Something went wrong. Please try again.';

    if (decoded is Map<String, dynamic>) {
      message = decoded['message']?.toString() ??
          decoded['error']?.toString() ??
          message;

      if (decoded['errors'] is Map) {
        final errors = decoded['errors'] as Map;
        if (errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) {
            message = first.first.toString();
          }
        }
      }
    }

    throw ApiException(
      message: message,
      statusCode: response.statusCode,
      response: decoded,
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic response;

  ApiException({
    required this.message,
    required this.statusCode,
    this.response,
  });

  @override
  String toString() => message;
}
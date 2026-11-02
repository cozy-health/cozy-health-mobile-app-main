import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../api/api_client.dart';
import '../services/local_db_service.dart';

class RecordedAudio {
  const RecordedAudio(this.path, this.duration);
  final String path;
  final int duration;
}

class VoiceAudio {
  static Future<Directory> directory() async {
    final owner = LocalDbService().activeUserId;
    if (owner == null) throw StateError('Sign in to save a recording.');
    final root = await getApplicationSupportDirectory();
    if (owner != LocalDbService().activeUserId) {
      throw StateError('Account changed.');
    }
    final folder = Directory(
      '${root.path}/voice/${Uri.encodeComponent(owner)}',
    );
    await folder.create(recursive: true);
    final settings = await LocalDbService().settingsBox();
    if (owner != LocalDbService().activeUserId) {
      throw StateError('Account changed.');
    }
    await settings.put('has_voice_files', true);
    return folder;
  }

  static Future<String> save(RecordedAudio audio, String id) async {
    final owner = LocalDbService().activeUserId;
    await _checkFileOwner(audio.path, temporaryAllowed: true);
    final folder = await directory();
    if (owner != LocalDbService().activeUserId) {
      throw StateError('Account changed.');
    }
    final saved = await File(audio.path).copy('${folder.path}/$id.m4a');
    if (owner != LocalDbService().activeUserId) {
      throw StateError('Account changed.');
    }
    return saved.path;
  }

  static Future<String> upload({
    required RecordedAudio audio,
    required String clientId,
    int? conversationId,
    ApiClient? api,
  }) async {
    final owner = LocalDbService().activeUserId;
    await _checkFileOwner(audio.path, temporaryAllowed: conversationId != null);
    if (owner != LocalDbService().activeUserId) {
      throw StateError('Account changed.');
    }
    final form = FormData.fromMap({
      'client_id': clientId,
      'purpose': conversationId == null ? 'journal' : 'message',
      if (conversationId != null) 'provider_client_link_id': conversationId,
      'duration': audio.duration,
      'audio': await MultipartFile.fromFile(audio.path, filename: 'voice.m4a'),
    });
    if (owner != LocalDbService().activeUserId) {
      throw StateError('Account changed.');
    }
    final response = await (api ?? ApiClient.instance).post(
      '/audio-attachments',
      data: form,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(minutes: 2),
      ),
    );
    if (owner != LocalDbService().activeUserId) {
      throw StateError('Account changed.');
    }
    final data = response.data as Map;
    return data['id'] as String;
  }

  // Keep temporary recorder previews supported, but never accept another
  // account's durable recording (including a symlink to one).
  static Future<void> _checkFileOwner(
    String source, {
    bool temporaryAllowed = false,
  }) async {
    final owner = LocalDbService().activeUserId;
    if (owner == null) throw StateError('Sign in to access a recording.');
    final root = await getApplicationSupportDirectory();
    final canonicalRoot = await root.resolveSymbolicLinks();
    final voiceRoot = Directory(
      '$canonicalRoot/voice',
    ).absolute.uri.normalizePath().path;
    final folder = Directory(
      '$canonicalRoot/voice/${Uri.encodeComponent(owner)}',
    ).absolute.uri.normalizePath().path;
    final file = File(source);
    final resolved = File(
      await file.resolveSymbolicLinks(),
    ).absolute.uri.normalizePath().path;
    if (owner != LocalDbService().activeUserId ||
        (!resolved.startsWith(folder) &&
            (!temporaryAllowed || resolved.startsWith(voiceRoot)))) {
      throw StateError('Recording belongs to another account.');
    }
  }

  static Future<void> removeLocal(String? path) async {
    if (path == null || path.isEmpty) return;
    final folder = await directory();
    final file = File(path);
    if (file.absolute.uri.normalizePath().path.startsWith(
          folder.absolute.uri.normalizePath().path,
        ) &&
        await file.exists()) {
      await file.delete();
    }
  }

  static Future<void> clearAccount() async {
    final owner = LocalDbService().activeUserId;
    if (owner == null) return;
    final settings = await LocalDbService().settingsBox();
    if (owner != LocalDbService().activeUserId) {
      throw StateError('Account changed.');
    }
    if (settings.get('has_voice_files') != true) return;
    final folder = await directory();
    final exists = await folder.exists();
    if (owner != LocalDbService().activeUserId) {
      throw StateError('Account changed.');
    }
    if (exists) await folder.delete(recursive: true);
  }

  static Future<String> playable(
    String source, {
    ApiClient? api,
    bool journal = false,
  }) async {
    final owner = LocalDbService().activeUserId;
    if (!source.startsWith('/audio-attachments/')) {
      await _checkFileOwner(source);
      if (!await File(source).exists()) {
        throw StateError('Recording is unavailable on this device.');
      }
      if (owner != LocalDbService().activeUserId) {
        throw StateError('Account changed.');
      }
      return source;
    }
    final id = source.substring('/audio-attachments/'.length);
    if (!RegExp(r'^[a-f0-9-]{36}$').hasMatch(id)) {
      throw StateError('Invalid recording.');
    }
    final folder = await directory();
    final path = '${folder.path}/remote_$id.m4a';
    final cached = journal && await File(path).exists();
    if (owner != LocalDbService().activeUserId) {
      throw StateError('Account changed.');
    }
    if (cached) return path;
    // Chat playback is always authorized, including after relationship revocation.
    final response = await (api ?? ApiClient.instance).get(
      source,
      options: Options(responseType: ResponseType.bytes),
    );
    if (owner != LocalDbService().activeUserId) {
      throw StateError('Account changed.');
    }
    await File(
      path,
    ).writeAsBytes((response.data as List).cast<int>(), flush: true);
    if (owner != LocalDbService().activeUserId) {
      throw StateError('Account changed.');
    }
    return path;
  }
}

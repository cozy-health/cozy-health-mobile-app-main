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
    final folder = await directory();
    return (await File(audio.path).copy('${folder.path}/$id.m4a')).path;
  }

  static Future<String> upload({
    required RecordedAudio audio,
    required String clientId,
    int? conversationId,
    ApiClient? api,
  }) async {
    final owner = LocalDbService().activeUserId;
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
    if (LocalDbService().activeUserId == null) return;
    final settings = await LocalDbService().settingsBox();
    if (settings.get('has_voice_files') != true) return;
    final folder = await directory();
    if (await folder.exists()) await folder.delete(recursive: true);
  }

  static Future<String> playable(
    String source, {
    ApiClient? api,
    bool journal = false,
  }) async {
    if (!source.startsWith('/audio-attachments/')) {
      if (!await File(source).exists()) {
        throw StateError('Recording is unavailable on this device.');
      }
      return source;
    }
    final id = source.substring('/audio-attachments/'.length);
    if (!RegExp(r'^[a-f0-9-]{36}$').hasMatch(id)) {
      throw StateError('Invalid recording.');
    }
    final owner = LocalDbService().activeUserId;
    final folder = await directory();
    final path = '${folder.path}/remote_$id.m4a';
    if (journal && await File(path).exists()) return path;
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
    return path;
  }
}

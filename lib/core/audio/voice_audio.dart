import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../api/api_client.dart';
import '../services/local_db_service.dart';
import '../storage/token_storage.dart';

/// A revocable capability for one temporary recording in the current session.
class VoicePreview {
  VoicePreview._(this.path, this._owner, this._generation);
  final String path;
  final String? _owner;
  final int _generation;
  bool _active = true;

  static VoicePreview create(String path) {
    return VoicePreview._(
      path,
      LocalDbService().activeUserId,
      TokenStorage.generation,
    );
  }

  Future<void> _check(String source) async {
    if (!_allows(source)) throw StateError('Preview has ended.');
    final owner = LocalDbService().activeUserId;
    final generation = TokenStorage.generation;
    final temporary = await getTemporaryDirectory();
    final root = Directory(
      await temporary.resolveSymbolicLinks(),
    ).uri.normalizePath().path;
    final resolved = File(
      await File(path).resolveSymbolicLinks(),
    ).uri.normalizePath().path;
    if (owner == null ||
        owner != LocalDbService().activeUserId ||
        generation != TokenStorage.generation ||
        !resolved.startsWith(root)) {
      throw StateError('Preview is unavailable.');
    }
    // A durable file must still pass account ownership checks.
    await VoiceAudio._checkFileOwner(path, temporaryAllowed: true);
    if (!_allows(source)) throw StateError('Preview has ended.');
  }

  void invalidate() => _active = false;

  bool _allows(String source) =>
      _active &&
      _owner != null &&
      source == path &&
      _owner == LocalDbService().activeUserId &&
      _generation == TokenStorage.generation;
}

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
  static Future<String> _canonicalFilePath(File file) async {
    if (await file.exists()) return file.resolveSymbolicLinks();

    // A removed file cannot resolve its own links. Resolve its nearest existing
    // directory instead, so aliases such as macOS /var and /private/var agree.
    var ancestor = file.parent;
    final missing = <String>[file.uri.pathSegments.last];
    while (!await ancestor.exists()) {
      final parent = ancestor.parent;
      if (parent.path == ancestor.path) {
        throw FileSystemException(
          'Recording directory is unavailable.',
          file.path,
        );
      }
      missing.insert(
        0,
        ancestor.uri.pathSegments.where((part) => part.isNotEmpty).last,
      );
      ancestor = parent;
    }
    return File(
      '${await ancestor.resolveSymbolicLinks()}/${missing.join('/')}',
    ).path;
  }

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
    final file = File(source).absolute;
    final resolved = File(
      await _canonicalFilePath(file),
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
    String? localPath,
    VoicePreview? preview,
    bool onlineOnly = false,
  }) async {
    final owner = LocalDbService().activeUserId;
    if (preview != null && !onlineOnly) {
      await preview._check(source);
      return source;
    }
    if (!onlineOnly && localPath != null && localPath.isNotEmpty) {
      await _checkFileOwner(localPath);
      final exists = await File(localPath).exists();
      if (owner != LocalDbService().activeUserId) {
        throw StateError('Account changed.');
      }
      if (exists) return localPath;
    }
    if (onlineOnly) {
      if (!RegExp(
        r'^/provider-conversations/\d+/journal-shares/[a-f0-9-]{36}/audio$',
      ).hasMatch(source)) {
        throw StateError('Invalid shared recording.');
      }
      final response = await (api ?? ApiClient.instance).get(
        source,
        options: Options(responseType: ResponseType.bytes),
      );
      if (owner == null || owner != LocalDbService().activeUserId) {
        throw StateError('Account changed.');
      }
      final temporary = await getTemporaryDirectory();
      final file = await File(
        '${temporary.path}/cozy_shared_${DateTime.now().microsecondsSinceEpoch}.m4a',
      ).writeAsBytes((response.data as List).cast<int>(), flush: true);
      if (owner != LocalDbService().activeUserId) {
        await file.delete();
        throw StateError('Account changed.');
      }
      return file.path;
    }
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

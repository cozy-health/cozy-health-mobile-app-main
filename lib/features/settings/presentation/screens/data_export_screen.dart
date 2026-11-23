import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/storage/token_storage.dart';

class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key, this.local, this.tokens, this.sharing});

  final LocalDbService? local;
  final TokenStorage? tokens;
  final SharePlus? sharing;
  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  bool _busy = false;
  String? _status;
  Future<void> _export() async {
    if (_busy) return;
    final local = widget.local ?? LocalDbService();
    final tokens = widget.tokens ?? TokenStorage();
    final owner = local.activeUserId;
    final generation = TokenStorage.generation;
    bool active() =>
        mounted &&
        owner == local.activeUserId &&
        generation == TokenStorage.generation;
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      if (owner == null || owner.startsWith('guest_')) {
        if (active()) {
          setState(() => _status = 'Sign in to export your account data.');
        }
        return;
      }
      final token = await tokens.getToken();
      if (!active()) return;
      if (token == null) {
        setState(() => _status = 'Sign in to export your account data.');
        return;
      }
      final payload = {
        'exported_at': DateTime.now().toUtc().toIso8601String(),
        'scope':
            'Records currently saved on this device. Cloud-only records and audio files are not included.',
        'profile': local.getUserProfile()?.toJson(),
        'moods': local.getAllMoodEntries().map((row) => row.toJson()).toList(),
        'journals': local
            .getAllJournalEntries()
            .map((row) => row.toJson()..remove('local_voice_path'))
            .toList(),
        'conversations': local
            .getAllChatConversations()
            .map((row) => row.toJson())
            .toList(),
        'messages': local.chatMessageBox.values
            .map((row) => row.toJson())
            .toList(),
      };
      final box = await local.settingsBox();
      if (!active()) return;
      final currentToken = await tokens.getToken();
      if (!active() || currentToken == null) return;
      final result = await (widget.sharing ?? SharePlus.instance).share(
        ShareParams(
          files: [
            XFile.fromData(
              utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)),
              mimeType: 'application/json',
            ),
          ],
          fileNameOverrides: ['cozy-device-data.json'],
        ),
      );
      if (!active()) return;
      if (result.status == ShareResultStatus.success) {
        await box.put(
          'last_device_export',
          DateTime.now().toUtc().toIso8601String(),
        );
        if (!active()) return;
        setState(() => _status = 'Export shared.');
      } else {
        setState(
          () => _status =
              'The share sheet closed. No download or delivery has been confirmed.',
        );
      }
    } catch (_) {
      if (active()) {
        setState(
          () => _status = 'Could not create or share the export. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Export your saved data')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Create a JSON file containing the account details, mood logs, journals, and conversations currently saved on this device.',
        ),
        const SizedBox(height: 16),
        const Text(
          'This is a device export, not a complete cloud archive. Cloud-only records and audio files are not included. No export email is sent.',
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _export,
          child: Text(_busy ? 'Preparing…' : 'Create and share JSON'),
        ),
        if (_status != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(_status!),
          ),
      ],
    ),
  );
}

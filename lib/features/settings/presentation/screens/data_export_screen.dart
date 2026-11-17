import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/services/local_db_service.dart';
import '../../../../core/storage/token_storage.dart';

class DataExportScreen extends StatefulWidget {
  const DataExportScreen({super.key});
  @override
  State<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends State<DataExportScreen> {
  bool _busy = false;
  String? _status;
  Future<void> _export() async {
    if (_busy) return;
    final local = LocalDbService();
    final owner = local.activeUserId;
    if (owner == null ||
        owner.startsWith('guest_') ||
        await TokenStorage().getToken() == null) {
      if (mounted) {
        setState(() => _status = 'Sign in to export your account data.');
      }
      return;
    }
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
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
      if (owner != local.activeUserId ||
          await TokenStorage().getToken() == null) {
        return;
      }
      final box = await local.settingsBox();
      final result = await SharePlus.instance.share(
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
      if (owner != local.activeUserId || !mounted) return;
      if (result.status == ShareResultStatus.success) {
        await box.put(
          'last_device_export',
          DateTime.now().toUtc().toIso8601String(),
        );
        setState(() => _status = 'Export shared.');
      } else {
        setState(
          () => _status =
              'The share sheet closed. No download or delivery has been confirmed.',
        );
      }
    } catch (_) {
      if (mounted) {
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

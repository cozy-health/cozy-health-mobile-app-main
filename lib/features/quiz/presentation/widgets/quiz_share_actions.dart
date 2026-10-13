import 'dart:io';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/models/quiz_attempt.dart';
import '../../../settings/data/settings_service.dart';
import '../../data/quiz_repository.dart';
import 'provider_share_confirm_dialog.dart';
import 'quiz_session_guard.dart';
import '../../../../core/api/api_exceptions.dart';

class QuizShareActions extends StatefulWidget {
  const QuizShareActions({super.key, required this.attempt});
  final QuizAttempt attempt;
  @override
  State<QuizShareActions> createState() => _QuizShareActionsState();
}

class _QuizShareActionsState extends State<QuizShareActions>
    with QuizSessionGuard<QuizShareActions> {
  Map? _provider;
  bool _busy = false;
  String? _message;
  @override
  void initState() {
    super.initState();
    _loadProvider();
  }

  Future<void> _loadProvider() async {
    try {
      final result = await SettingsService().getProvider();
      if (mounted && isQuizSessionActive) {
        setState(
          () => _provider = result['has_provider'] == true
              ? result['provider'] as Map?
              : null,
        );
      }
    } catch (_) {}
  }

  Future<bool> _confirm(String title, String text) async =>
      await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(title),
              content: Text(text),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ) ==
          true &&
      isQuizSessionActive;
  Future<String?> _input(String title) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    controller.dispose();
    return isQuizSessionActive ? value : null;
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy || !isQuizSessionActive) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'Could not complete this action. Check your connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _friend() async {
    final username = await _input('Friend’s username');
    if (username == null || username.isEmpty) return;
    dynamic response;
    try {
      response = await ApiClient.instance.get(
        '/quizzes/recipients/resolve',
        queryParameters: {'username': username},
      );
    } on ApiException catch (error) {
      if (error.statusCode != 404) rethrow;
      if (mounted && isQuizSessionActive) {
        setState(
          () => _message =
              'Username not found. Use “Invite a friend with a link” below.',
        );
      }
      return;
    }
    final recipient = response.data['data'] as Map;
    if (!mounted ||
        !isQuizSessionActive ||
        !await _confirm(
          'Share with @${recipient['username']}?',
          'Share this result’s title, total, interpretation, date and recommendations. Individual answers stay private.',
        )) {
      return;
    }
    await ApiClient.instance.post(
      '/quizzes/attempts/${widget.attempt.id}/friends',
      data: {'recipient_id': recipient['id'], 'consent': true},
    );
    if (mounted) setState(() => _message = 'Result shared.');
  }

  Future<void> _providerShare() async {
    final provider = _provider;
    if (provider == null || provider['status'] != 'verified') return;
    if (!mounted ||
        !isQuizSessionActive ||
        await ProviderShareConfirmDialog.show(
              context,
              providerName:
                  (provider['provider_name'] ??
                          provider['name'] ??
                          'your linked provider')
                      .toString(),
            ) !=
            true ||
        !isQuizSessionActive) {
      return;
    }
    await ApiClient.instance.post(
      '/quizzes/attempts/${widget.attempt.id}/share',
      data: {
        'provider_id': provider['provider_id'],
        'consent': true,
        'enable_quiz_consent': true,
      },
    );
    if (mounted) {
      setState(
        () => _message = 'Result available in your provider’s dashboard.',
      );
    }
  }

  Future<void> _invite() async {
    if (!await _confirm(
      'Invite a friend?',
      'The first person who signs in, finishes onboarding and accepts this link can view this result summary. Forwarding the link before acceptance can let someone else claim it. The link expires in seven days.',
    )) {
      return;
    }
    final response = await ApiClient.instance.post(
      '/quizzes/attempts/${widget.attempt.id}/invitations',
      data: {'consent': true},
    );
    final url = response.data['data']['url'] as String;
    if (!mounted || !isQuizSessionActive) return;
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text:
            'I shared a result with you on Cozy Health. Install the app, then reopen this link to view it: $url',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Future<void> _pdf() async {
    if (!await _confirm(
      'Export PDF?',
      'The PDF contains your result summary. Downloaded or shared copies cannot be revoked.',
    )) {
      return;
    }
    final response = await ApiClient.instance.get(
      '/quizzes/attempts/${widget.attempt.id}/pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    if (!mounted || !isQuizSessionActive) return;
    final root = await getTemporaryDirectory();
    final directory = Directory('${root.path}/cozy_quiz_exports');
    await directory.create(recursive: true);
    final file = File('${directory.path}/assessment-result.pdf');
    try {
      await file.writeAsBytes(List<int>.from(response.data as List));
      if (!mounted || !isQuizSessionActive) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> _grants() async {
    final response = await ApiClient.instance.get(
      '/quizzes/attempts/${widget.attempt.id}/grants',
    );
    final data = response.data['data'] as Map;
    if (!mounted || !isQuizSessionActive) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(title: Text('Manage sharing')),
              for (final kind in ['friend', 'provider', 'invitation'])
                for (final grant in data[kind] as List)
                  if ((grant as Map)['revoked_at'] == null)
                    ListTile(
                      title: Text(
                        '$kind ${grant['recipient_id'] ?? grant['provider_id'] ?? ''}',
                      ),
                      subtitle: Text(
                        kind == 'invitation'
                            ? 'Expires ${grant['expires_at']}'
                            : 'Selected result only',
                      ),
                      trailing: TextButton(
                        onPressed: () async {
                          if (!isQuizSessionActive) return;
                          try {
                            await ApiClient.instance.delete(
                              '/quizzes/attempts/${widget.attempt.id}/grants/$kind/${grant['id']}',
                            );
                            if (context.mounted && isQuizSessionActive) {
                              update(() => grant['revoked_at'] = 'revoked');
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Could not revoke sharing. Try again.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Revoke'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.attempt.isValidated && !_busy && isQuizSessionActive;
    final linked = _provider != null && _provider!['status'] == 'verified';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.attempt.isValidated)
          Text(
            widget.attempt.validationState == 'rejected'
                ? 'This result could not be validated. Start a new assessment or delete this saved result.'
                : 'Connect to validate and share this result.',
          ),
        if (_message != null) Text(_message!),
        if (_busy) const LinearProgressIndicator(),
        OutlinedButton(
          onPressed: enabled ? () => _run(_friend) : null,
          child: const Text('Share with friend'),
        ),
        OutlinedButton(
          onPressed: enabled ? () => _run(_invite) : null,
          child: const Text('Invite a friend with a link'),
        ),
        ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: linked ? 0 : 1.5,
            sigmaY: linked ? 0 : 1.5,
          ),
          child: OutlinedButton(
            onPressed: enabled && linked ? () => _run(_providerShare) : null,
            child: const Text('Share with provider'),
          ),
        ),
        if (!linked)
          TextButton(
            onPressed: () => context.push('/my-provider'),
            child: const Text('Link a provider'),
          ),
        OutlinedButton(
          onPressed: enabled ? () => _run(_pdf) : null,
          child: const Text('Export PDF'),
        ),
        TextButton(
          onPressed: !_busy ? () => _run(_grants) : null,
          child: const Text('Manage sharing'),
        ),
        TextButton(
          onPressed: !_busy
              ? () => _run(() async {
                  if (await _confirm(
                    'Delete result?',
                    'Remove this result from your history and revoke shared access? Downloaded PDFs cannot be removed.',
                  )) {
                    await QuizRepository().deleteAttempt(widget.attempt.id);
                    if (context.mounted) context.pop();
                  }
                })
              : null,
          child: const Text('Delete result'),
        ),
      ],
    );
  }
}

Future<void> cleanupQuizExports() async {
  final root = await getTemporaryDirectory();
  final file = File('${root.path}/cozy_quiz_exports/assessment-result.pdf');
  if (await file.exists()) await file.delete();
}

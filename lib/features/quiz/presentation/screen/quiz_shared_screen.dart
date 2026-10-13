import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exceptions.dart';
import '../../data/quiz_invitation_service.dart';
import '../widgets/quiz_session_guard.dart';

class QuizSharedScreen extends StatefulWidget {
  const QuizSharedScreen({super.key, this.shareId});
  final String? shareId;
  @override
  State<QuizSharedScreen> createState() => _QuizSharedScreenState();
}

class _QuizSharedScreenState extends State<QuizSharedScreen>
    with QuizSessionGuard<QuizSharedScreen>, WidgetsBindingObserver {
  dynamic _data;
  String? _error;
  bool _loading = true;
  int _requestSerial = 0;
  int _page = 1;
  int _lastPage = 1;
  @override
  void onQuizSessionEnded() {
    _requestSerial++;
    _data = null;
    _loading = false;
    _error = 'Sign in again to view shared results.';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _requestSerial++;
      setState(() => _data = null);
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    if (!isQuizSessionActive) return;
    final request = ++_requestSerial;
    setState(() {
      _loading = true;
      _data = null;
      _error = null;
    });
    try {
      final response = await ApiClient.instance.get(
        widget.shareId == null
            ? '/quizzes/shared'
            : '/quizzes/shared/${widget.shareId}',
        queryParameters: widget.shareId == null ? {'page': _page} : null,
      );
      if (mounted && isQuizSessionActive && request == _requestSerial) {
        setState(() {
          _data = response.data['data'];
          if (widget.shareId == null) {
            _lastPage = (_data['last_page'] as num).toInt();
          }
        });
      }
    } catch (_) {
      if (mounted && request == _requestSerial && isQuizSessionActive) {
        setState(
          () => _error =
              'This shared result is unavailable. It may have been revoked, or you may need to reconnect.',
        );
      }
    } finally {
      if (mounted && request == _requestSerial) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.shareId == null ? 'Shared with me' : 'Shared result'),
    ),
    body: SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : _data == null
          ? const Center(child: Text('No result available.'))
          : widget.shareId == null
          ? ListView(
              children: [
                for (final row in (_data as Map)['data'] as List)
                  ListTile(
                    title: Text(row['sender'] as String),
                    subtitle: Text(
                      '${row['quiz_title']} · ${row['completed_at']}',
                    ),
                    leading: Icon(
                      row['read_at'] == null
                          ? Icons.markunread_outlined
                          : Icons.drafts_outlined,
                    ),
                    onTap: () => context.push('/quiz-shared/${row['id']}'),
                    trailing: IconButton(
                      tooltip: 'Dismiss',
                      icon: const Icon(Icons.close),
                      onPressed: () async {
                        try {
                          await ApiClient.instance.delete(
                            '/quizzes/shared/${row['id']}',
                          );
                          _load();
                        } catch (_) {}
                      },
                    ),
                  ),
                if (((_data as Map)['data'] as List).isEmpty)
                  const ListTile(title: Text('No shared results yet.')),
                TextButton(onPressed: _load, child: const Text('Refresh')),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _page > 1
                          ? () {
                              _page--;
                              _load();
                            }
                          : null,
                      child: const Text('Previous'),
                    ),
                    Text('Page $_page of $_lastPage'),
                    TextButton(
                      onPressed: _page < _lastPage
                          ? () {
                              _page++;
                              _load();
                            }
                          : null,
                      child: const Text('Next'),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.push('/quiz-invitation'),
                  child: const Text('Continue pending invitation'),
                ),
                TextButton(
                  onPressed: () => context.push('/quiz-username'),
                  child: const Text('Set your username to receive results'),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  _data['quiz_title'] as String,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  '${_data['score']} / ${_data['maximum_score']}',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                Text(_data['interpretation'] as String),
                Text('Completed ${_data['completed_at']}'),
                Text(_data['recommendation'] as String? ?? ''),
                const SizedBox(height: 20),
                Text(_data['disclaimer'] as String? ?? ''),
                const Text(
                  'Not a substitute for professional care. This is not a diagnosis.',
                ),
              ],
            ),
    ),
  );
}

class QuizUsernameScreen extends StatefulWidget {
  const QuizUsernameScreen({super.key});
  @override
  State<QuizUsernameScreen> createState() => _QuizUsernameScreenState();
}

class _QuizUsernameScreenState extends State<QuizUsernameScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _busy = false;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final username = _controller.text.trim();
      if (!RegExp(r'^[A-Za-z0-9_]{3,50}$').hasMatch(username)) {
        setState(() => _error = 'Use 3–50 letters, numbers or underscores.');
        return;
      }
      await ApiClient.instance.patch(
        '/user/profile',
        data: {'username': username},
      );
      if (mounted) context.pop();
    } on ApiValidationException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not save your username. Please reconnect and retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your username')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Friends can use this unique username to share selected results with you.',
          ),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Username',
              errorText: _error,
            ),
          ),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(_busy ? 'Saving…' : 'Save username'),
          ),
        ],
      ),
    ),
  );
}

class QuizInvitationScreen extends StatefulWidget {
  const QuizInvitationScreen({super.key});
  @override
  State<QuizInvitationScreen> createState() => _QuizInvitationScreenState();
}

class _QuizInvitationScreenState extends State<QuizInvitationScreen>
    with QuizSessionGuard<QuizInvitationScreen> {
  String? _message;
  bool _busy = false;
  Future<void> _accept() async {
    if (!isQuizSessionActive) return;
    setState(() => _busy = true);
    try {
      final token = await QuizInvitationService.instance.pending();
      if (!isQuizSessionActive) return;
      if (token == null) {
        setState(
          () => _message = 'No active invitation. Reopen your original link.',
        );
        return;
      }
      final response = await ApiClient.instance.post(
        '/quizzes/invitations/claim',
        data: {'token': token, 'consent': true},
      );
      if (!isQuizSessionActive) return;
      await QuizInvitationService.instance.clear();
      if (mounted) {
        context.pushReplacement(
          '/quiz-shared/${response.data['data']['share_id']}',
        );
      }
    } on ApiException catch (error) {
      if (const [404, 410].contains(error.statusCode)) {
        await QuizInvitationService.instance.clear();
      }
      if (mounted) {
        setState(
          () => _message =
              'Could not accept. Sign in, finish onboarding and reconnect. The link may also have expired or already been accepted.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Could not accept. Please reconnect and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Accept shared result')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Someone shared an assessment summary with you. Accepting this invitation gives your current Cozy Health account access to that selected result.',
          ),
          if (_message != null) Text(_message!),
          FilledButton(
            onPressed: _busy ? null : _accept,
            child: Text(_busy ? 'Accepting…' : 'Accept invitation'),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () async {
                    await QuizInvitationService.instance.clear();
                    if (context.mounted) context.pop();
                  },
            child: const Text('Cancel invitation'),
          ),
        ],
      ),
    ),
  );
}

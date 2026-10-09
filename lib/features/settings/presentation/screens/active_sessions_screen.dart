import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/services/local_db_service.dart';
import '../../data/session_repository.dart';

class ActiveSessionsScreen extends StatefulWidget {
  const ActiveSessionsScreen({super.key, this.repository});
  final SessionRepository? repository;
  @override
  State<ActiveSessionsScreen> createState() => _ActiveSessionsScreenState();
}

class _ActiveSessionsScreenState extends State<ActiveSessionsScreen> {
  late final _repository = widget.repository ?? SessionRepository();
  List<Map<String, dynamic>> _sessions = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await _repository.list();
      if (mounted) {
        setState(() {
          _sessions = rows;
          _loading = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to load sessions. Try again.';
        });
      }
    }
  }

  Future<void> _signOutLocally() async {
    await TokenStorage().clearToken();
    await LocalDbService.instance.activateGuest();
    if (mounted) context.go(AppRouter.login);
  }

  Future<bool> _revoke(Map<String, dynamic> row) async {
    if (_busy) return false;
    setState(() => _busy = true);
    try {
      await _repository.revoke(row['id'].toString());
      if (row['is_current'] == true) {
        await _signOutLocally();
        return false;
      }
      if (mounted) {
        setState(() => _sessions.removeWhere((s) => s['id'] == row['id']));
      }
      return false;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not revoke session. Try again.')),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _all() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out all devices?'),
        content: const Text(
          'This includes this device. You will need to sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out all'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _repository.revokeAll();
      await _signOutLocally();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not sign out all devices. Try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Active Sessions')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: TextButton(onPressed: _load, child: Text(_error!)),
          )
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              children: [
                for (final row in _sessions)
                  Dismissible(
                    key: ValueKey(row['id']),
                    direction: _busy
                        ? DismissDirection.none
                        : DismissDirection.endToStart,
                    confirmDismiss: (_) => _revoke(row),
                    background: const ColoredBox(
                      color: Colors.red,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Icon(Icons.logout),
                      ),
                    ),
                    child: ListTile(
                      title: Text(row['device']?.toString() ?? 'Device'),
                      subtitle: Text(
                        'Last used: ${row['last_used'] ?? 'Unknown'}',
                      ),
                      leading: const Icon(Icons.devices),
                      trailing: row['is_current'] == true
                          ? const Text('This device')
                          : IconButton(
                              tooltip: 'Revoke session',
                              onPressed: _busy ? null : () => _revoke(row),
                              icon: const Icon(Icons.logout),
                            ),
                    ),
                  ),
                if (_sessions.isEmpty)
                  const ListTile(title: Text('No active sessions.')),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: FilledButton(
                    onPressed: _busy ? null : _all,
                    child: const Text('Log out all devices'),
                  ),
                ),
              ],
            ),
          ),
  );
}

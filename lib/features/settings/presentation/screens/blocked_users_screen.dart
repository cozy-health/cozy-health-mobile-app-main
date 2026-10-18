import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/local_db_service.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key, this.blockedUsers});
  final List<String>? blockedUsers;
  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final _owner = LocalDbService().activeUserId;
  List<Map<String, dynamic>> _rows = [];
  bool _busy = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    if (widget.blockedUsers != null) {
      setState(() {
        _rows = [
          for (final name in widget.blockedUsers!) {'name': name},
        ];
        _busy = false;
      });
      return;
    }
    try {
      final rows = <Map<String, dynamic>>[];
      var page = 1, last = 1;
      do {
        final response = await ApiClient().get(
          '/community/blocked',
          query: {'page': page, 'per_page': 50},
        );
        final data = response.data['data'] as Map;
        rows.addAll(
          (data['data'] as List).map(
            (row) => Map<String, dynamic>.from(row as Map),
          ),
        );
        last = (data['last_page'] as num).toInt();
        page++;
      } while (page <= last);
      if (mounted && _owner == LocalDbService().activeUserId) {
        setState(() => _rows = rows);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not load blocked users. Community may be unavailable.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unblock(Map row) async {
    if (row['id'] == null || _owner != LocalDbService().activeUserId) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unblock ${row['name']}?'),
        content: const Text(
          'They may be able to interact with you in community again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await ApiClient().delete('/community/users/${row['id']}/block');
      await _load();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not unblock this person. Please retry.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Blocked users')),
    body: _busy
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (_error != null) ...[
                Text(_error!),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
              if (_rows.isEmpty && _error == null)
                const Text("You haven't blocked anyone."),
              for (final row in _rows)
                ListTile(
                  title: Text('${row['name']}'),
                  trailing: TextButton(
                    onPressed: row['id'] == null ? null : () => _unblock(row),
                    child: const Text('Unblock'),
                  ),
                ),
            ],
          ),
  );
}

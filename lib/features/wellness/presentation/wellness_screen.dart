import 'package:cozy_health/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import '../../../core/widgets/plan_access_prompt.dart';
import '../../../core/repositories/wellness_repository.dart';

class WellnessScreen extends StatefulWidget {
  const WellnessScreen({super.key, this.packages = false});
  final bool packages;
  @override
  State<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends State<WellnessScreen> {
  final repository = WellnessRepository();
  List<Map<String, dynamic>>? rows;
  String? error;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final catalog = widget.packages ? await repository.catalog() : null;
      if (widget.packages && catalog == null) {
        throw StateError('Catalog unavailable');
      }
      final data = widget.packages
          ? (catalog!['packages'] as List)
                .where(
                  (row) =>
                      row is Map &&
                      const [
                        'standard',
                        'student',
                        'premium',
                      ].contains(row['tier']),
                )
                .map((row) => Map<String, dynamic>.from(row as Map))
                .toList()
          : await repository.challenges();
      if (mounted) {
        setState(() {
          rows = data;
          error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Could not load ${widget.packages ? 'packages' : 'challenges'}. Please retry.',
        );
      }
    }
  }

  Future<void> _action(Future<void> Function() action) async {
    if (!await ensurePlanAccess(context, 'challenges') || !mounted) return;
    setState(() => busy = true);
    try {
      await action();
      await _load();
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(
          context,
          const SnackBar(
            content: Text(
              'Could not save progress. Check your connection and task availability.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.packages ? 'Cozy Packages' : 'Cozy Challenges'),
    ),
    body: error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error!),
                TextButton(onPressed: _load, child: const Text('Try again')),
              ],
            ),
          )
        : rows == null
        ? const Center(child: CircularProgressIndicator())
        : rows!.isEmpty
        ? Center(
            child: Text(
              widget.packages
                  ? 'No packages are available yet.'
                  : 'No challenges are available yet.',
            ),
          )
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: rows!.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final row = rows![index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (row[widget.packages ? 'package_name' : 'name'] ?? '')
                              .toString(),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text((row['description'] ?? '').toString()),
                        if (widget.packages) ...[
                          const SizedBox(height: 12),
                          Text(
                            '${row['currency']} ${row['price']} / ${row['duration']}',
                          ),
                          for (final feature in row['features'] as List? ?? [])
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text('• $feature'),
                            ),
                          const SizedBox(height: 12),
                          const Text('Purchasing is not available yet.'),
                        ] else ...[
                          const SizedBox(height: 12),
                          Text('${row['duration_days']} days'),
                          if (row['enrolled'] != true)
                            FilledButton(
                              onPressed: busy
                                  ? null
                                  : () => _action(
                                      () => repository.enroll(row['id'] as int),
                                    ),
                              child: const Text('Join challenge'),
                            )
                          else ...[
                            for (final (day, task)
                                in (row['tasks'] as List).indexed)
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text('Day ${day + 1}: $task'),
                                value: (row['completed_days'] as List).contains(
                                  day + 1,
                                ),
                                onChanged:
                                    busy ||
                                        (row['completed_days'] as List)
                                            .contains(day + 1)
                                    ? null
                                    : (_) => _action(
                                        () => repository.complete(
                                          row['id'] as int,
                                          day + 1,
                                        ),
                                      ),
                              ),
                          ],
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
  );
}

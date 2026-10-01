import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ActiveSessionsScreen extends StatefulWidget {
  const ActiveSessionsScreen({super.key});

  @override
  State<ActiveSessionsScreen> createState() => _ActiveSessionsScreenState();
}

class _ActiveSessionsScreenState extends State<ActiveSessionsScreen> {
  final List<Map<String, dynamic>> _sessions = [
    {
      'id': '1',
      'device': 'iPhone 13 Pro',
      'location': 'San Francisco, CA',
      'time': 'Active now',
      'isCurrent': true,
      'icon': Icons.phone_iphone,
    },
    {
      'id': '2',
      'device': 'MacBook Pro 14"',
      'location': 'San Francisco, CA',
      'time': 'Last active 2 hours ago',
      'isCurrent': false,
      'icon': Icons.laptop_mac,
    },
    {
      'id': '3',
      'device': 'Chrome on Windows',
      'location': 'Seattle, WA',
      'time': 'Last active yesterday',
      'isCurrent': false,
      'icon': Icons.desktop_windows,
    },
  ];

  void _revokeAll() {
    setState(() {
      _sessions.removeWhere((s) => !s['isCurrent']);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All other sessions revoked')),
    );
  }

  void _revokeSession(String id) {
    setState(() {
      _sessions.removeWhere((s) => s['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session revoked')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasOtherSessions = _sessions.any((s) => !s['isCurrent']);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        title: Text(
          'Active Sessions',
          style: AppTextStyles.heading2.copyWith(color: AppColors.text),
        ),
        centerTitle: false,
        actions: [
          if (hasOtherSessions)
            TextButton(
              onPressed: _revokeAll,
              child: Text(
                'Revoke all',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _sessions.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                itemCount: _sessions.length,
                itemBuilder: (context, index) {
                  final session = _sessions[index];
                  final isCurrent = session['isCurrent'] as bool;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.warmBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            session['icon'] as IconData,
                            color: AppColors.text,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      session['device'] as String,
                                      style: AppTextStyles.body1.copyWith(
                                        color: AppColors.text,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (isCurrent)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'This device',
                                        style: AppTextStyles.body2.copyWith(
                                          color: AppColors.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${session['location']} • ${session['time']}',
                                style: AppTextStyles.body2.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isCurrent) ...[
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.logout, color: AppColors.danger),
                            tooltip: 'Revoke session',
                            onPressed: () => _revokeSession(session['id'] as String),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

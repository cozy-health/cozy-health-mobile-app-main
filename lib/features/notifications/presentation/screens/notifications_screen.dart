import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../utils/responsive_extensions.dart';
import '../../data/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  bool _loading = true;
  String? _error;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _notificationService.getNotifications();

      final notifications = response['notifications'];
      final data = notifications is Map<String, dynamic>
          ? notifications['data'] as List<dynamic>? ?? []
          : [];

      setState(() {
        _notifications = data;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Unable to load notifications.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await _notificationService.markAsRead(id);
      await _loadNotifications();
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      await _loadNotifications();
    } catch (_) {}
  }

  String _title(Map<String, dynamic> item) {
    final data = item['data'];

    if (data is Map<String, dynamic>) {
      return data['title']?.toString() ?? 'Notification';
    }

    return 'Notification';
  }

  String _message(Map<String, dynamic> item) {
    final data = item['data'];

    if (data is Map<String, dynamic>) {
      return data['message']?.toString() ?? '';
    }

    return '';
  }

  bool _isUnread(Map<String, dynamic> item) {
    return item['read_at'] == null;
  }

  void _handleNotificationTap(Map<String, dynamic> item) {
    final id = item['id']?.toString();

    if (id != null) {
      _markAsRead(id);
    }

    final title = _title(item).toLowerCase();

    if (title.contains('mood')) {
      context.push(AppRouter.moodFeeling);
      return;
    }

    if (title.contains('journal')) {
      context.push(AppRouter.journal);
      return;
    }

    if (title.contains('quiz')) {
      context.push(AppRouter.quizSelection);
      return;
    }

    if (title.contains('subscription')) {
      context.push(AppRouter.subscription);
      return;
    }

    if (title.contains('provider')) {
      context.push(AppRouter.provider);
      return;
    }
  }

  String _iconForTitle(String title) {
    final lower = title.toLowerCase();

    if (lower.contains('mood')) return '😊';
    if (lower.contains('journal')) return '💭';
    if (lower.contains('quiz')) return '🧠';
    if (lower.contains('subscription')) return '💳';
    if (lower.contains('provider')) return '🩺';

    return '🔔';
  }

  Color _colorForTitle(String title) {
    final lower = title.toLowerCase();

    if (lower.contains('mood')) return const Color(0xFFFFF4E5);
    if (lower.contains('journal')) return AppColors.lightGrey;
    if (lower.contains('quiz')) return const Color(0xFFF0F4FF);
    if (lower.contains('subscription')) return const Color(0xFFF8F0FF);
    if (lower.contains('provider')) return const Color(0xFFE5FFEA);

    return AppColors.lightGrey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notifications',
          style: AppTextStyles.heading2,
        ),
        centerTitle: true,
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Read all',
                style: AppTextStyles.linkText.copyWith(fontSize: 13),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(6.w),
                    child: Text(
                      _error!,
                      style: AppTextStyles.body1.copyWith(
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _notifications.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 12,
                        ),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) => 4.sh,
                        itemBuilder: (context, index) {
                          final item =
                              _notifications[index] as Map<String, dynamic>;

                          final title = _title(item);
                          final message = _message(item);
                          final unread = _isUnread(item);

                          return _buildNotificationCard(
                            icon: _iconForTitle(title),
                            title: title,
                            description: message,
                            actionText: unread ? 'Open' : 'View',
                            color: _colorForTitle(title),
                            isUnread: unread,
                            onTap: () => _handleNotificationTap(item),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            Assets.svg.noNotification,
            width: 120,
            height: 120,
          ),
          6.sh,
          Text(
            'No new notifications for now.\nCheck back later',
            style: AppTextStyles.body1,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required String icon,
    required String title,
    required String description,
    required String actionText,
    required Color color,
    required bool isUnread,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: isUnread
              ? Border.all(
                  color: AppColors.primary.withOpacity(0.4),
                  width: 1.5,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 28)),
                3.w.sw,
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.heading2.copyWith(
                      fontSize: 18,
                    ),
                  ),
                ),
                if (isUnread)
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            3.sh,
            Text(
              description.isEmpty ? 'You have a new update.' : description,
              style: AppTextStyles.body1,
            ),
            4.sh,
            Text(
              '$actionText →',
              style: AppTextStyles.linkText.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
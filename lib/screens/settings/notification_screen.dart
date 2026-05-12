import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/app_palette.dart';
import '../../widgets/state_widgets.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await _api.getNotifications();
      if (mounted) setState(() { _notifications = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'AI_REPORT': return Icons.auto_awesome;
      case 'IDEA_UPDATE': return Icons.lightbulb;
      case 'SYSTEM': return Icons.info_outline;
      default: return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'AI_REPORT': return AppPalette.aiGlow;
      case 'IDEA_UPDATE': return AppPalette.primaryAccent;
      case 'SYSTEM': return AppPalette.info;
      default: return AppPalette.textSecondary;
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      appBar: AppBar(
        backgroundColor: AppPalette.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20, color: AppPalette.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const ShimmerList(count: 5, cardHeight: 80)
          : _notifications.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.notifications_none,
                  title: 'No notifications yet',
                  subtitle: 'You\'ll see updates about your ideas and AI reports here.',
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: AppPalette.primaryAccent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) => _buildNotificationCard(_notifications[index]),
                  ),
                ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final type = notification['type'] ?? 'SYSTEM';
    final isRead = notification['read'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isRead ? AppPalette.surfaceCard : AppPalette.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead ? Colors.grey.shade100 : AppPalette.primaryAccent.withOpacity(0.3),
        ),
        boxShadow: isRead
            ? []
            : [BoxShadow(color: AppPalette.primaryAccent.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            if (!isRead) {
              try {
                await _api.markNotificationRead(notification['id']);
                setState(() => notification['read'] = true);
              } catch (_) {}
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _colorForType(type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_iconForType(type), color: _colorForType(type), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification['title'] ?? 'Notification',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                color: AppPalette.textPrimary,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppPalette.primaryAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification['message'] ?? '',
                        style: const TextStyle(fontSize: 13, color: AppPalette.textSecondary, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _timeAgo(notification['createdAt']),
                        style: const TextStyle(fontSize: 11, color: AppPalette.textTerenary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

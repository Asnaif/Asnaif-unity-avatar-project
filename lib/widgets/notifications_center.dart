import 'package:flutter/material.dart';
import 'package:interprep/models/notification.dart';
import 'package:interprep/services/notification_service.dart';

class NotificationsCenter extends StatefulWidget {
  const NotificationsCenter({super.key});

  @override
  State<NotificationsCenter> createState() => _NotificationsCenterState();
}

class _NotificationsCenterState extends State<NotificationsCenter> {
  final NotificationService _notificationService = NotificationService();
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await _notificationService.getNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String id) async {
    await _notificationService.markAsRead(id);
    _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    await _notificationService.markAllAsRead();
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = _filterNotifications(_notifications);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.any((n) => !n.read))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark All Read'),
            ),
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _filter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All')),
              const PopupMenuItem(value: 'Unread', child: Text('Unread')),
              const PopupMenuItem(value: 'Achievements', child: Text('Achievements')),
              const PopupMenuItem(value: 'Goals', child: Text('Goals')),
              const PopupMenuItem(value: 'Tips', child: Text('Tips')),
            ],
            child: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredNotifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: filteredNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = filteredNotifications[index];
                    return _buildNotificationTile(notification);
                  },
                ),
    );
  }

  List<AppNotification> _filterNotifications(List<AppNotification> notifications) {
    switch (_filter) {
      case 'Unread':
        return notifications.where((n) => !n.read).toList();
      case 'Achievements':
        return notifications.where((n) => n.type == NotificationType.achievement).toList();
      case 'Goals':
        return notifications.where((n) => n.type == NotificationType.goal).toList();
      case 'Tips':
        return notifications.where((n) => n.type == NotificationType.tip).toList();
      default:
        return notifications;
    }
  }

  Widget _buildNotificationTile(AppNotification notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _notificationService.deleteNotification(notification.id);
        _loadNotifications();
      },
      child: ListTile(
        leading: _getNotificationIcon(notification.type),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text(notification.message),
        trailing: notification.read
            ? null
            : IconButton(
                icon: const Icon(Icons.circle, size: 12, color: Colors.blue),
                onPressed: () => _markAsRead(notification.id),
              ),
        onTap: () {
          if (!notification.read) {
            _markAsRead(notification.id);
          }
        },
      ),
    );
  }

  Widget _getNotificationIcon(NotificationType type) {
    IconData icon;
    Color color;

    switch (type) {
      case NotificationType.achievement:
        icon = Icons.workspace_premium;
        color = Colors.amber;
        break;
      case NotificationType.goal:
        icon = Icons.flag;
        color = Colors.green;
        break;
      case NotificationType.reminder:
        icon = Icons.alarm;
        color = Colors.blue;
        break;
      case NotificationType.tip:
        icon = Icons.lightbulb;
        color = Colors.orange;
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.2),
      child: Icon(icon, color: color, size: 20),
    );
  }
}





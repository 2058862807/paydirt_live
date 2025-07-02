import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/realtime_notifications_service.dart';
import './widgets/notification_card_widget.dart';
import './widgets/notification_empty_state_widget.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      final service = RealtimeNotificationsService();
      await service.initializeNotifications();

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Failed to initialize notifications: $e');
      setState(() {
        _isInitialized = true; // Still show UI even if initialization fails
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to notification stream
    ref.listen<AsyncValue<Map<String, dynamic>>>(notificationStreamProvider,
        (previous, next) {
      next.whenData((notification) {
        setState(() {
          _notifications.insert(0, notification);
        });

        // Show in-app notification
        _showInAppNotification(notification);
      });
    });

    return Scaffold(
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        appBar: _buildAppBar(),
        body: _isInitialized ? _buildBody() : _buildLoadingState(),
        floatingActionButton: _buildTestNotificationButton());
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
        backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: CustomIconWidget(
                iconName: 'arrow_back',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 24)),
        title: Text('Notifications',
            style: AppTheme.lightTheme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
                onPressed: _clearAllNotifications,
                icon: CustomIconWidget(
                    iconName: 'clear_all',
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    size: 24)),
          SizedBox(width: 2.w),
        ]);
  }

  Widget _buildLoadingState() {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.lightTheme.colorScheme.primary)),
      SizedBox(height: 2.h),
      Text('Initializing real-time notifications...',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurface
                  .withValues(alpha: 0.7))),
    ]));
  }

  Widget _buildBody() {
    if (_notifications.isEmpty) {
      return const NotificationEmptyStateWidget();
    }

    return Column(children: [
      _buildNotificationHeader(),
      Expanded(
          child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return Padding(
                    padding: EdgeInsets.only(bottom: 2.h),
                    child: NotificationCardWidget(
                        notification: notification,
                        isSelectionMode: false,
                        isSelected: false,
                        onArchive: () {},
                        onDelete: () => _dismissNotification(index),
                        onLongPress: () {},
                        onMarkAsRead: () => _markAsRead(index),
                        onTap: () => _markAsRead(index)));
              })),
    ]);
  }

  Widget _buildNotificationHeader() {
    final unreadCount =
        _notifications.where((n) => !(n['isRead'] ?? false)).length;

    return Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Recent Notifications',
              style: AppTheme.lightTheme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          if (unreadCount > 0)
            Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Text('$unreadCount unread',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w600))),
        ]));
  }

  Widget _buildTestNotificationButton() {
    return FloatingActionButton.extended(
        onPressed: _sendTestNotification,
        backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
        foregroundColor: AppTheme.lightTheme.colorScheme.onSecondary,
        icon: CustomIconWidget(
            iconName: 'notification_add',
            color: AppTheme.lightTheme.colorScheme.onSecondary,
            size: 20),
        label: Text('Test',
            style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSecondary,
                fontWeight: FontWeight.w600)));
  }

  void _showInAppNotification(Map<String, dynamic> notification) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          CustomIconWidget(
              iconName: notification['icon'] ?? 'notification',
              color: AppTheme.lightTheme.colorScheme.onPrimary,
              size: 20),
          SizedBox(width: 2.w),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                Text(notification['title'] ?? '',
                    style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600)),
                Text(notification['body'] ?? '',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onPrimary
                            .withValues(alpha: 0.9)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ])),
        ]),
        backgroundColor: notification['isPositive'] ?? true
            ? AppTheme.lightTheme.colorScheme.primary
            : AppTheme.lightTheme.colorScheme.error,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(4.w)));
  }

  void _markAsRead(int index) {
    setState(() {
      _notifications[index]['isRead'] = true;
    });
  }

  void _dismissNotification(int index) {
    setState(() {
      _notifications.removeAt(index);
    });
  }

  void _clearAllNotifications() {
    setState(() {
      _notifications.clear();
    });
  }

  Future<void> _sendTestNotification() async {
    try {
      final service = RealtimeNotificationsService();
      await service.sendTestNotification();
    } catch (e) {
      print('Failed to send test notification: $e');
    }
  }
}
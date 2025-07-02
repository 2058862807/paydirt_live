import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class RealtimeNotificationsService {
  static final RealtimeNotificationsService _instance =
      RealtimeNotificationsService._internal();

  factory RealtimeNotificationsService() {
    return _instance;
  }

  RealtimeNotificationsService._internal();

  // Stream controller for notifications
  final StreamController<Map<String, dynamic>> _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Notification stream getter
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationStreamController.stream;

  // Initialize notification monitoring
  Future<void> initializeNotifications() async {
    try {
      final supabaseService = SupabaseService();
      final client = await supabaseService.client;

      // Listen for new activities that should trigger notifications
      client
          .channel('notification_activities')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'activities',
            callback: (payload) {
              _handleNewActivity(payload.newRecord);
            },
          )
          .subscribe();

      // Listen for revenue metric updates
      client
          .channel('notification_revenue')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'revenue_metrics',
            callback: (payload) {
              _handleRevenueUpdate(payload.newRecord);
            },
          )
          .subscribe();

      print('Notification monitoring initialized');
    } catch (error) {
      print('Failed to initialize notification monitoring: $error');
    }
  }

  // Handle new activity notifications
  void _handleNewActivity(Map<String, dynamic>? record) {
    if (record == null) return;

    final activityType = record['activity_type'] as String?;
    final title = record['title'] as String?;
    final amount = record['amount'] as num?;
    final isPositive = record['is_positive'] as bool? ?? true;

    if (activityType != null && title != null && amount != null) {
      // Create notification based on activity type
      String notificationTitle;
      String notificationBody;
      String notificationIcon;

      switch (activityType) {
        case 'payment':
          notificationTitle = 'Payment Received';
          notificationBody = '$title - \$${amount.toStringAsFixed(2)}';
          notificationIcon = 'payment';
          break;
        case 'refund':
          notificationTitle = 'Refund Processed';
          notificationBody = '$title - \$${amount.abs().toStringAsFixed(2)}';
          notificationIcon = 'refund';
          break;
        case 'subscription':
          notificationTitle = 'Subscription Update';
          notificationBody = '$title - \$${amount.toStringAsFixed(2)}';
          notificationIcon = 'subscription';
          break;
        case 'invoice':
          notificationTitle = 'Invoice Generated';
          notificationBody = '$title - \$${amount.toStringAsFixed(2)}';
          notificationIcon = 'invoice';
          break;
        default:
          notificationTitle = 'New Activity';
          notificationBody = title;
          notificationIcon = 'notification';
      }

      // Send notification through stream
      _notificationStreamController.add({
        'id': record['id'],
        'title': notificationTitle,
        'body': notificationBody,
        'icon': notificationIcon,
        'type': activityType,
        'amount': amount,
        'isPositive': isPositive,
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
      });
    }
  }

  // Handle revenue update notifications
  void _handleRevenueUpdate(Map<String, dynamic>? record) {
    if (record == null) return;

    final totalRevenue = record['total_revenue'] as num?;
    final revenueChange = record['revenue_change'] as num?;
    final isPositiveChange = record['is_positive_change'] as bool? ?? true;

    if (totalRevenue != null && revenueChange != null) {
      // Send revenue update notification
      _notificationStreamController.add({
        'id': 'revenue_update_${DateTime.now().millisecondsSinceEpoch}',
        'title': 'Revenue Updated',
        'body':
            'Total revenue: \$${_formatCurrency(totalRevenue.toDouble())} (${isPositiveChange ? '+' : ''}${revenueChange.toStringAsFixed(1)}%)',
        'icon': isPositiveChange ? 'trending_up' : 'trending_down',
        'type': 'revenue_update',
        'amount': totalRevenue,
        'isPositive': isPositiveChange,
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
      });
    }
  }

  // Format currency for notifications
  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(2);
    }
  }

  // Send test notification
  Future<void> sendTestNotification() async {
    _notificationStreamController.add({
      'id': 'test_${DateTime.now().millisecondsSinceEpoch}',
      'title': 'Test Notification',
      'body': 'This is a test notification from PayDirt Live',
      'icon': 'notification',
      'type': 'test',
      'amount': 0,
      'isPositive': true,
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': false,
    });
  }

  // Dispose resources
  void dispose() {
    _notificationStreamController.close();
  }
}

// Provider for notifications

final notificationServiceProvider =
    Provider<RealtimeNotificationsService>((ref) {
  return RealtimeNotificationsService();
});

final notificationStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final service = ref.watch(notificationServiceProvider);
  return service.notificationStream;
});

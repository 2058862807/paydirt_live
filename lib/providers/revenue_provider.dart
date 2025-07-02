import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

// Real-time revenue data provider
final revenueProvider = StreamProvider<double>((ref) async* {
  final supabaseService = SupabaseService();

  try {
    // Initialize real-time subscriptions
    await supabaseService.initializeRealTimeSubscriptions();

    // Get initial data
    final initialData = await supabaseService.getRevenueData();
    yield (initialData['total_revenue'] as num?)?.toDouble() ?? 0.0;

    // Listen to real-time updates
    await for (final revenueData in supabaseService.revenueStream) {
      yield (revenueData['total_revenue'] as num?)?.toDouble() ?? 0.0;
    }
  } catch (e) {
    print('Revenue provider error: $e');
    // Yield default value on error
    yield 0.0;
  }
});

// Real-time metrics provider
final metricsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final supabaseService = SupabaseService();

  try {
    // Get initial data
    final initialData = await supabaseService.getMetrics();
    yield initialData;

    // Listen to real-time updates
    await for (final metrics in supabaseService.metricsStream) {
      yield metrics;
    }
  } catch (e) {
    print('Metrics provider error: $e');
    // Yield empty list on error
    yield [];
  }
});

// Real-time activities provider
final activitiesProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final supabaseService = SupabaseService();

  try {
    // Get initial data
    final initialData = await supabaseService.getRecentActivities();
    yield initialData;

    // Listen to real-time updates
    await for (final activities in supabaseService.activitiesStream) {
      yield activities;
    }
  } catch (e) {
    print('Activities provider error: $e');
    // Yield empty list on error
    yield [];
  }
});

// Connection status provider
final connectionStatusProvider = StreamProvider<bool>((ref) async* {
  final supabaseService = SupabaseService();

  // Check connection every 30 seconds
  while (true) {
    try {
      final isConnected = await supabaseService.checkConnection();
      yield isConnected;
      await Future.delayed(const Duration(seconds: 30));
    } catch (e) {
      yield false;
      await Future.delayed(
          const Duration(seconds: 10)); // Retry faster on error
    }
  }
});

// Manual refresh provider
final refreshTriggerProvider = StateProvider<int>((ref) => 0);

// Helper provider to trigger manual refresh
final manualRefreshProvider = Provider<Future<void>>((ref) async {
  final supabaseService = SupabaseService();

  try {
    // Force refresh all data
    final revenueData = await supabaseService.getRevenueData();
    final metrics = await supabaseService.getMetrics();
    final activities = await supabaseService.getRecentActivities();

    // Update revenue metrics
    await supabaseService.updateRevenueMetrics();

    // Increment refresh trigger to invalidate cached data
    ref.read(refreshTriggerProvider.notifier).state++;
  } catch (e) {
    print('Manual refresh error: $e');
    throw Exception('Failed to refresh data: $e');
  }
});

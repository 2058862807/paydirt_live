import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late final SupabaseClient _client;
  bool _isInitialized = false;
  final Future<void> _initFuture;

  // Real-time subscriptions
  RealtimeChannel? _revenueChannel;
  RealtimeChannel? _activitiesChannel;
  RealtimeChannel? _metricsChannel;

  // Stream controllers for real-time data
  final StreamController<Map<String, dynamic>> _revenueStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<List<Map<String, dynamic>>>
      _activitiesStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _metricsStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  // Singleton pattern
  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal() : _initFuture = _initializeSupabase();

  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  // Internal initialization logic
  static Future<void> _initializeSupabase() async {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception(
          'SUPABASE_URL and SUPABASE_ANON_KEY must be defined using --dart-define.');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );

    _instance._client = Supabase.instance.client;
    _instance._isInitialized = true;
  }

  // Client getter (async)
  Future<SupabaseClient> get client async {
    if (!_isInitialized) {
      await _initFuture;
    }
    return _client;
  }

  // Stream getters for real-time data
  Stream<Map<String, dynamic>> get revenueStream =>
      _revenueStreamController.stream;
  Stream<List<Map<String, dynamic>>> get activitiesStream =>
      _activitiesStreamController.stream;
  Stream<List<Map<String, dynamic>>> get metricsStream =>
      _metricsStreamController.stream;

  // Initialize real-time subscriptions
  Future<void> initializeRealTimeSubscriptions() async {
    try {
      final client = await this.client;

      // Subscribe to revenue metrics changes
      _revenueChannel = client
          .channel('revenue_metrics_channel')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'revenue_metrics',
            callback: (payload) async {
              try {
                // Fetch updated revenue data
                final revenueData = await getRevenueData();
                _revenueStreamController.add(revenueData);
              } catch (e) {
                print('Error updating revenue stream: $e');
              }
            },
          )
          .subscribe();

      // Subscribe to activities changes
      _activitiesChannel = client
          .channel('activities_channel')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'activities',
            callback: (payload) async {
              try {
                // Fetch updated activities
                final activities = await getRecentActivities();
                _activitiesStreamController.add(activities);
              } catch (e) {
                print('Error updating activities stream: $e');
              }
            },
          )
          .subscribe();

      // Subscribe to metrics changes
      _metricsChannel = client
          .channel('metrics_channel')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'key_metrics',
            callback: (payload) async {
              try {
                // Fetch updated metrics
                final metrics = await getMetrics();
                _metricsStreamController.add(metrics);
              } catch (e) {
                print('Error updating metrics stream: $e');
              }
            },
          )
          .subscribe();

      print('Real-time subscriptions initialized successfully');
    } catch (error) {
      print('Failed to initialize real-time subscriptions: $error');
      throw Exception('Failed to initialize real-time subscriptions: $error');
    }
  }

  // Revenue data operations
  Future<Map<String, dynamic>> getRevenueData() async {
    try {
      final client = await this.client;
      final response = await client
          .from('revenue_metrics')
          .select('*')
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to fetch revenue data: $error');
    }
  }

  Future<List<Map<String, dynamic>>> getMetrics() async {
    try {
      final client = await this.client;
      final response = await client
          .from('key_metrics')
          .select('*')
          .order('updated_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch metrics: $error');
    }
  }

  Future<List<Map<String, dynamic>>> getRecentActivities() async {
    try {
      final client = await this.client;
      final response = await client
          .from('activities')
          .select('*')
          .order('timestamp', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch activities: $error');
    }
  }

  // Create new activity (for testing real-time updates)
  Future<Map<String, dynamic>> createActivity({
    required String activityType,
    required String title,
    required String description,
    required double amount,
    required bool isPositive,
  }) async {
    try {
      final client = await this.client;
      final response = await client
          .from('activities')
          .insert({
            'activity_type': activityType,
            'title': title,
            'description': description,
            'amount': amount,
            'is_positive': isPositive,
            'timestamp': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return response;
    } catch (error) {
      throw Exception('Failed to create activity: $error');
    }
  }

  // Update revenue metrics
  Future<void> updateRevenueMetrics() async {
    try {
      final client = await this.client;
      await client.rpc('update_revenue_metrics');
    } catch (error) {
      throw Exception('Failed to update revenue metrics: $error');
    }
  }

  // Get connection status
  Future<bool> checkConnection() async {
    try {
      final client = await this.client;
      await client.from('revenue_metrics').select('id').limit(1);
      return true;
    } catch (error) {
      return false;
    }
  }

  // Cleanup real-time subscriptions
  Future<void> dispose() async {
    try {
      final client = await this.client;

      if (_revenueChannel != null) {
        await client.removeChannel(_revenueChannel!);
      }
      if (_activitiesChannel != null) {
        await client.removeChannel(_activitiesChannel!);
      }
      if (_metricsChannel != null) {
        await client.removeChannel(_metricsChannel!);
      }

      await _revenueStreamController.close();
      await _activitiesStreamController.close();
      await _metricsStreamController.close();
    } catch (error) {
      print('Error disposing Supabase service: $error');
    }
  }
}

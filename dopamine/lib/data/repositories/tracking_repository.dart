import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_client.dart';
import '../services/app_tracking_service.dart';

final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final trackingService = ref.watch(appTrackingServiceProvider);
  return TrackingRepository(client, trackingService);
});

class TrackingRepository {
  final SupabaseClient _supabase;
  final AppTrackingService _trackingService;

  TrackingRepository(this._supabase, this._trackingService);

  /// Syncs usage data from Device -> Supabase for specific apps
  Future<void> syncAppUsage(List<String> packageNames) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final today = DateTime.now().toIso8601String().split('T')[0];

    for (var pkg in packageNames) {
      // 1. Get real data from device (Android)
      final stats = await _trackingService.getUsageStats(pkg);
      final duration = stats['duration'] as int; // Milliseconds
      final opens = stats['opens'] as int;

      if (duration > 0 || opens > 0) {
        // 2. Upsert to Supabase
        await _supabase.from('app_usage_logs').upsert({
          'user_id': userId,
          'log_date': today,
          'app_package_name': pkg,
          'duration_seconds': (duration / 1000).round(),
          'opens_count': opens,
        }, onConflict: 'user_id, log_date, app_package_name');
      }
    }
  }

  /// Fetches aggregated usage stats for the dashboard (Last 7 days)
  Future<List<Map<String, dynamic>>> getWeeklyUsageHistory() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final startDate = DateTime.now().subtract(const Duration(days: 7));
    final startDateStr = startDate.toIso8601String().split('T')[0];

    try {
      final response = await _supabase
          .from('app_usage_logs')
          .select('log_date, duration_seconds, opens_count')
          .eq('user_id', userId)
          .gte('log_date', startDateStr)
          .order('log_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching usage history: $e');
      return [];
    }
  }
}

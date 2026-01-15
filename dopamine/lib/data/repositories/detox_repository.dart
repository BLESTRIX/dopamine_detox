import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_client.dart';

// Manual Provider definition for the Detox Repository
final detoxRepositoryProvider = Provider<DetoxRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return DetoxRepository(client);
});

class DetoxRepository {
  final SupabaseClient _supabase;

  DetoxRepository(this._supabase);

  /// Starts a new detox session in Supabase
  Future<Map<String, dynamic>> startSession({
    required int durationMinutes,
    required List<String> restrictedApps,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User must be authenticated');

    try {
      final response = await _supabase
          .from('detox_sessions')
          .insert({
            'user_id': userId,
            // ✅ FIX: Send UTC time to ensure consistent timezone handling
            'start_time': DateTime.now().toUtc().toIso8601String(),
            'target_duration_minutes': durationMinutes,
            'status': 'active',
            'pause_count': 0,
            // metadata column now exists as JSONB
            'metadata': {
              'restricted_apps': restrictedApps,
              'device_info': {
                'platform':
                    'android', // Could be dynamic based on Platform.isAndroid
                'app_version': '1.0.0',
              },
            },
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to start detox session: $e');
    }
  }

  /// Updates the session status (completed or failed)
  Future<void> updateSessionStatus(String sessionId, String status) async {
    try {
      await _supabase
          .from('detox_sessions')
          .update({
            'status': status,
            'end_time': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);
    } catch (e) {
      throw Exception('Failed to update session: $e');
    }
  }

  /// Increments the pause count, enforcing the "only once" rule
  Future<void> pauseSession(String sessionId) async {
    try {
      // Use the RPC function that enforces the business rule
      await _supabase.rpc(
        'increment_pause_count',
        params: {'session_id': sessionId},
      );
    } catch (e) {
      // The RPC function will throw a descriptive error if pause limit reached
      throw Exception(
        'Could not pause: ${e.toString().contains('Pause limit') ? 'You have already used your one allowed pause' : e.toString()}',
      );
    }
  }

  /// Fetches the currently active session for the authenticated user
  /// Required for offline-friendly recovery on app restart
  Future<Map<String, dynamic>?> getActiveSession() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('detox_sessions')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  /// Get restricted apps from active session
  Future<List<String>> getRestrictedApps(String sessionId) async {
    try {
      final response = await _supabase
          .from('detox_sessions')
          .select('metadata')
          .eq('id', sessionId)
          .single();

      final metadata = response['metadata'] as Map<String, dynamic>?;
      if (metadata == null) return [];

      final apps = metadata['restricted_apps'] as List<dynamic>?;
      return apps?.map((e) => e.toString()).toList() ?? [];
    } catch (e) {
      print('Error fetching restricted apps: $e');
      return [];
    }
  }

  /// Resume session (clears pause state)
  Future<void> resumeSession(String sessionId) async {
    try {
      // Note: We don't decrement pause_count (business rule: once paused, always counts)
      // We just update the status back to 'active'
      await _supabase
          .from('detox_sessions')
          .update({'status': 'active'})
          .eq('id', sessionId);
    } catch (e) {
      throw Exception('Failed to resume session: $e');
    }
  }

  /// Get session statistics for dashboard
  Future<Map<String, dynamic>> getSessionStats() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return {};

    try {
      final response = await _supabase
          .from('detox_sessions')
          .select('status, target_duration_minutes')
          .eq('user_id', userId);

      int totalSessions = response.length;
      int completedSessions = 0;
      int totalMinutes = 0;

      for (var session in response) {
        if (session['status'] == 'completed') {
          completedSessions++;
          totalMinutes += (session['target_duration_minutes'] as int? ?? 0);
        }
      }

      return {
        'total_sessions': totalSessions,
        'completed_sessions': completedSessions,
        'total_minutes': totalMinutes,
        'success_rate': totalSessions > 0
            ? (completedSessions / totalSessions * 100).toStringAsFixed(1)
            : '0.0',
      };
    } catch (e) {
      print('Error fetching session stats: $e');
      return {};
    }
  }
}

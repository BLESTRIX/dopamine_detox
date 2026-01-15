import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_client.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ActivityRepository(client);
});

class ActivityRepository {
  final SupabaseClient _supabase;

  ActivityRepository(this._supabase);

  // 1. GET SUGGESTED ACTIVITIES
  Future<List<Map<String, dynamic>>> getActivitiesByCategory(
    String category,
  ) async {
    try {
      final response = await _supabase
          .from('activities')
          .select()
          .eq('category', category)
          .order('title', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching activities: $e');
      return [];
    }
  }

  // 2. LOG CUSTOM ACTIVITY (The one triggering your errors)
  Future<void> logCustomActivity({
    required String title,
    required String category,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    try {
      // A. Check if activity already exists for this user (or global)
      final existing = await _supabase
          .from('activities')
          .select('id')
          .ilike('title', title)
          .eq('category', category)
          .maybeSingle();

      String activityId;

      if (existing != null) {
        activityId = existing['id'];
      } else {
        // B. Create new custom activity
        // NOTE: Ensure you ran the SQL to DROP the category check constraint!
        final newActivity = await _supabase
            .from('activities')
            .insert({
              'title': title,
              'category': category,
              'description':
                  'Custom user activity', // Satisfies not-null constraint
              'is_custom': true,
              'user_id': userId,
            })
            .select('id')
            .single();
        activityId = newActivity['id'];
      }

      // C. Log the completion
      await _supabase.from('activity_logs').insert({
        'user_id': userId,
        'activity_id': activityId,
        'completed_at': DateTime.now().toIso8601String(),
        'duration_minutes': 0,
      });
    } catch (e) {
      print("Error logging custom activity: $e");
      throw Exception('Failed to save activity: $e');
    }
  }

  // 3. GET ACTIVITY HISTORY
  Future<List<Map<String, dynamic>>> getActivityHistory() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // Joins activity_logs with activities table to get titles
      final response = await _supabase
          .from('activity_logs')
          .select('completed_at, duration_minutes, activities(title, category)')
          .eq('user_id', userId)
          .order('completed_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Error fetching history: $e");
      return [];
    }
  }

  // 4. LOG DURATION (For Timer/Detox)
  Future<void> logActivityCompletion({
    required String activityId,
    required int durationMinutes,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('activity_logs').insert({
        'user_id': userId,
        'activity_id': activityId,
        'duration_minutes': durationMinutes,
        'completed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error logging activity: $e');
    }
  }

  Future<List<String>> getAllCategories() async {
    try {
      // Fetch distinct categories from the 'activities' table
      final response = await _supabase.from('activities').select('category');

      // Convert to a unique list of strings
      final data = List<Map<String, dynamic>>.from(response);
      final categories = data
          .map((e) => e['category'] as String)
          .toSet()
          .toList();

      // Ensure we always have at least the defaults if DB is empty
      if (categories.isEmpty) {
        return ['Mindful', 'Physical', 'Creative', 'Educational'];
      }

      categories.sort(); // Sort alphabetically
      return categories;
    } catch (e) {
      print('Error fetching categories: $e');
      return ['Mindful', 'Physical', 'Creative', 'Educational'];
    }
  }
}

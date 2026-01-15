import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_client.dart';

final reflectionRepositoryProvider = Provider<ReflectionRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ReflectionRepository(client);
});

class ReflectionRepository {
  final SupabaseClient _supabase;

  ReflectionRepository(this._supabase);

  Future<void> saveReflection({
    required String moodKey,
    required String moodEmoji,
    required String text,
    required int energyLevel,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final String today = DateTime.now().toIso8601String().split('T')[0];

    try {
      await _supabase.from('reflections').upsert({
        'user_id': userId,
        'log_date': today,
        'mood_key': moodKey,
        'mood_emoji': moodEmoji,
        'reflection_text': text,
        'energy_level': energyLevel,
      }, onConflict: 'user_id, log_date');
    } catch (e) {
      throw Exception('Failed to save reflection: $e');
    }
  }

  Future<bool> hasReflectedToday() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;
    final String today = DateTime.now().toIso8601String().split('T')[0];

    try {
      final response = await _supabase
          .from('reflections')
          .select('id')
          .eq('user_id', userId)
          .eq('log_date', today)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  // ✅ ADDED: This missing method fixes the error in ChartsController
  Future<List<Map<String, dynamic>>> getReflectionHistory({
    int days = 7,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final startDate = DateTime.now().subtract(Duration(days: days));
    final startDateStr = startDate.toIso8601String().split('T')[0];

    try {
      final response = await _supabase
          .from('reflections')
          // ✅ ADDED: 'reflection_text' to the select list
          .select('log_date, mood_key, energy_level, reflection_text')
          .eq('user_id', userId)
          .gte('log_date', startDateStr)
          .order('log_date', ascending: false); // Recommended: Newest first

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching reflection history: $e');
      return [];
    }
  }
}

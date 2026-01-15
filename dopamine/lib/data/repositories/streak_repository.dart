import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_client.dart';

final streakRepositoryProvider = Provider<StreakRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return StreakRepository(client);
});

class StreakRepository {
  final SupabaseClient _supabase;

  StreakRepository(this._supabase);

  Future<Map<String, dynamic>?> getStreakData() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      return await _supabase
          .from('profiles')
          .select('current_streak, longest_streak, last_streak_update')
          .eq('user_id', userId)
          .single();
    } catch (e) {
      return null;
    }
  }

  // Logic: Increment Streak (Backend handles date logic)
  Future<void> incrementStreak() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _supabase.rpc(
        'handle_streak_increment',
        params: {'user_uuid': userId},
      );
    } catch (e) {
      print('Streak Increment Error: $e');
    }
  }

  // Logic: Reset Streak (Penalty)
  Future<void> resetStreak() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _supabase
          .from('profiles')
          .update({
            'current_streak': 0,
            'last_streak_update': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
    } catch (e) {
      print('Streak Reset Error: $e');
    }
  }
}

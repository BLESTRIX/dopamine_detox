import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileState {
  final bool isLoading;
  final String displayName;
  final String avatar; // ✅ ADDED
  final int dailyGoalMinutes;
  final bool notificationsEnabled;
  final int totalDetoxMinutes;
  final int badgesEarned;

  ProfileState({
    this.isLoading = false,
    this.displayName = '',
    this.avatar = '👤', // ✅ ADDED: Default
    this.dailyGoalMinutes = 60,
    this.notificationsEnabled = true,
    this.totalDetoxMinutes = 0,
    this.badgesEarned = 0,
  });

  ProfileState copyWith({
    bool? isLoading,
    String? displayName,
    String? avatar, // ✅ ADDED
    int? dailyGoalMinutes,
    bool? notificationsEnabled,
    int? totalDetoxMinutes,
    int? badgesEarned,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar, // ✅ ADDED
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      totalDetoxMinutes: totalDetoxMinutes ?? this.totalDetoxMinutes,
      badgesEarned: badgesEarned ?? this.badgesEarned,
    );
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
      return ProfileController(ref.watch(supabaseClientProvider));
    });

class ProfileController extends StateNotifier<ProfileState> {
  final _supabase;

  ProfileController(this._supabase) : super(ProfileState()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true);
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final profileResponse = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .single();

      final badgesResponse = await _supabase
          .from('user_badges')
          .select('id')
          .eq('user_id', userId);

      final sessionsResponse = await _supabase
          .from('detox_sessions')
          .select('target_duration_minutes')
          .eq('user_id', userId)
          .eq('status', 'completed');

      int totalMinutes = 0;
      for (var s in sessionsResponse) {
        totalMinutes += (s['target_duration_minutes'] as int);
      }

      final prefs = await SharedPreferences.getInstance();
      final goal = prefs.getInt('daily_goal') ?? 60;
      final notifs = prefs.getBool('notifications_enabled') ?? true;

      state = ProfileState(
        isLoading: false,
        displayName: profileResponse['display_name'] ?? 'User',
        avatar: profileResponse['avatar'] ?? '👤', // ✅ ADDED
        dailyGoalMinutes: goal,
        notificationsEnabled: notifs,
        totalDetoxMinutes: totalMinutes,
        badgesEarned: (badgesResponse as List).length,
      );
    } catch (e) {
      print('Profile Load Error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updateDailyGoal(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('daily_goal', minutes);
    state = state.copyWith(dailyGoalMinutes: minutes);
  }

  Future<void> toggleNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/streak_repository.dart';
import '../../core/supabase_client.dart';

class Badge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool isUnlocked;
  final DateTime? earnedAt;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
    this.earnedAt,
  });
}

class BadgesState {
  final List<Badge> badges;
  final bool isLoading;
  final String? errorMessage;

  BadgesState({
    this.badges = const [],
    this.isLoading = false,
    this.errorMessage,
  });
}

final badgesControllerProvider =
    StateNotifierProvider<BadgesController, BadgesState>((ref) {
      return BadgesController(
        ref.watch(streakRepositoryProvider),
        ref.watch(supabaseClientProvider),
      );
    });

class BadgesController extends StateNotifier<BadgesState> {
  final StreakRepository _streakRepo;
  final _supabase;

  BadgesController(this._streakRepo, this._supabase) : super(BadgesState()) {
    loadBadges();
  }

  Future<void> loadBadges() async {
    state = BadgesState(isLoading: true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User not logged in");

      // 1. Get basic stats for achievements
      final streakData = await _streakRepo.getStreakData();
      final currentStreak = streakData?['current_streak'] ?? 0;

      // Check count of activities (LIMIT 1 is enough to know if > 0)
      final activitiesRes = await _supabase
          .from('activity_logs')
          .select('id')
          .eq('user_id', userId)
          .limit(1);
      final hasActivity = (activitiesRes as List).isNotEmpty;

      // Check count of reflections
      final reflectionsRes = await _supabase
          .from('reflections')
          .select('id')
          .eq('user_id', userId)
          .limit(1);
      final hasReflection = (reflectionsRes as List).isNotEmpty;

      // 2. Get unlocked badges from DB
      final earnedBadges = await _supabase
          .from('user_badges')
          .select('badge_type, earned_at')
          .eq('user_id', userId);

      final earnedTypes = {
        for (var b in earnedBadges) b['badge_type'] as String,
      };

      // 3. Define All Badges
      final allBadges = [
        // --- BASIC ACHIEVEMENTS ---
        Badge(
          id: 'basic_1',
          name: 'First Step',
          description: 'Log your first healthy activity',
          icon: '👟',
          isUnlocked: earnedTypes.contains('First Step') || hasActivity,
        ),
        Badge(
          id: 'basic_2',
          name: 'Self Aware',
          description: 'Save your first daily reflection',
          icon: '🧠',
          isUnlocked: earnedTypes.contains('Self Aware') || hasReflection,
        ),

        // --- STREAK ACHIEVEMENTS ---
        Badge(
          id: 'streak_1',
          name: 'Focus Starter',
          description: 'Complete 3 consecutive days',
          icon: '🌱',
          isUnlocked:
              earnedTypes.contains('Focus Starter') || currentStreak >= 3,
        ),
        Badge(
          id: 'streak_2',
          name: 'Digital Monk',
          description: 'Maintain a 7-day streak',
          icon: '🧘',
          isUnlocked:
              earnedTypes.contains('Digital Monk') || currentStreak >= 7,
        ),
        Badge(
          id: 'streak_3',
          name: 'No Scroll Hero',
          description: 'Achieve a 30-day streak',
          icon: '👑',
          isUnlocked:
              earnedTypes.contains('No Scroll Hero') || currentStreak >= 30,
        ),
      ];

      state = BadgesState(badges: allBadges, isLoading: false);

      // 4. Auto-Award logic
      await _checkAndAward(userId, 'First Step', hasActivity, earnedTypes);
      await _checkAndAward(userId, 'Self Aware', hasReflection, earnedTypes);
      await _checkAndAward(
        userId,
        'Focus Starter',
        currentStreak >= 3,
        earnedTypes,
      );
      await _checkAndAward(
        userId,
        'Digital Monk',
        currentStreak >= 7,
        earnedTypes,
      );
      await _checkAndAward(
        userId,
        'No Scroll Hero',
        currentStreak >= 30,
        earnedTypes,
      );
    } catch (e) {
      state = BadgesState(isLoading: false, errorMessage: 'Error: $e');
    }
  }

  Future<void> _checkAndAward(
    String userId,
    String badgeName,
    bool condition,
    Set<String> earned,
  ) async {
    if (condition && !earned.contains(badgeName)) {
      try {
        await _supabase.from('user_badges').insert({
          'user_id': userId,
          'badge_type': badgeName,
          'earned_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {
        // Ignore duplicate key errors
      }
    }
  }
}

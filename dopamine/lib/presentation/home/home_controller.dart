import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/streak_repository.dart';
import '../../data/repositories/tracking_repository.dart';
import '../../data/repositories/detox_repository.dart';
import '../../data/services/quote_service.dart';
import '../../core/supabase_client.dart';

class HomeState {
  final int currentStreak;
  final int longestStreak;
  final int totalMinutesReclaimed;
  final int totalSessions;
  final int completedSessions;
  final bool hasActiveSession;
  final bool isLoading;
  final String? errorMessage;
  final String? quoteText;
  final String? quoteAuthor;
  final String userName;
  final String avatar;

  HomeState({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.totalMinutesReclaimed = 0,
    this.totalSessions = 0,
    this.completedSessions = 0,
    this.hasActiveSession = false,
    this.isLoading = false,
    this.errorMessage,
    this.quoteText,
    this.quoteAuthor,
    this.userName = 'Digital Minimalist',
    this.avatar = '👤',
  });

  HomeState copyWith({
    int? currentStreak,
    int? longestStreak,
    int? totalMinutesReclaimed,
    int? totalSessions,
    int? completedSessions,
    bool? hasActiveSession,
    bool? isLoading,
    String? errorMessage,
    String? quoteText,
    String? quoteAuthor,
    String? userName,
    String? avatar,
  }) {
    return HomeState(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalMinutesReclaimed:
          totalMinutesReclaimed ?? this.totalMinutesReclaimed,
      totalSessions: totalSessions ?? this.totalSessions,
      completedSessions: completedSessions ?? this.completedSessions,
      hasActiveSession: hasActiveSession ?? this.hasActiveSession,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      quoteText: quoteText ?? this.quoteText,
      quoteAuthor: quoteAuthor ?? this.quoteAuthor,
      userName: userName ?? this.userName,
      avatar: avatar ?? this.avatar,
    );
  }
}

final homeControllerProvider = StateNotifierProvider<HomeController, HomeState>(
  (ref) {
    return HomeController(
      ref.watch(streakRepositoryProvider),
      ref.watch(trackingRepositoryProvider),
      ref.watch(detoxRepositoryProvider),
      ref.watch(quoteServiceProvider),
      ref.watch(supabaseClientProvider),
    );
  },
);

class HomeController extends StateNotifier<HomeState> {
  final StreakRepository _streakRepo;
  final TrackingRepository _trackingRepo;
  final DetoxRepository _detoxRepo;
  final QuoteService _quoteService;
  final _supabase;

  // ✅ ENHANCEMENT: List of apps to sync usage for.
  // In a real app, this might come from user settings.
  static const List<String> _monitoredApps = [
    'com.instagram.android',
    'com.zhiliaoapp.musically', // TikTok
    'com.facebook.katana',
    'com.twitter.android',
    'com.google.android.youtube',
    'com.snapchat.android',
    'com.netflix.mediaclient',
    'com.reddit.frontpage',
  ];

  HomeController(
    this._streakRepo,
    this._trackingRepo,
    this._detoxRepo,
    this._quoteService,
    this._supabase,
  ) : super(HomeState()) {
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final userId = _supabase.auth.currentUser?.id;

      // ✅ ENHANCEMENT: Sync App Usage in the background
      // This pushes the latest "Time Spent" on Instagram/etc to Supabase
      // so the Charts screen has fresh data to show.
      // We don't await this to avoid blocking the UI loading.
      _trackingRepo.syncAppUsage(_monitoredApps).catchError((e) {
        print('Background Sync Failed: $e');
      });

      final results = await Future.wait<dynamic>([
        _streakRepo.getStreakData(), // 0
        _detoxRepo.getActiveSession(), // 1
        _detoxRepo.getSessionStats(), // 2
        _quoteService.fetchDailyQuote(), // 3
        if (userId != null)
          _supabase
              .from('profiles')
              .select('display_name, avatar')
              .eq('user_id', userId)
              .maybeSingle()
        else
          Future.value(null),
      ]);

      final streakData = results[0] as Map<String, dynamic>?;
      final activeSession = results[1] as Map<String, dynamic>?;
      final sessionStats = results[2] as Map<String, dynamic>? ?? {};
      final quote = results[3] as Quote?;
      final profileData = results[4] as Map<String, dynamic>?;

      final int totalMinutes = sessionStats['total_minutes'] ?? 0;

      state = state.copyWith(
        currentStreak: streakData?['current_streak'] ?? 0,
        longestStreak: streakData?['longest_streak'] ?? 0,
        totalMinutesReclaimed: totalMinutes,
        totalSessions: sessionStats['total_sessions'] ?? 0,
        completedSessions: sessionStats['completed_sessions'] ?? 0,
        hasActiveSession: activeSession != null,
        quoteText: quote?.content,
        quoteAuthor: quote?.author,
        userName: profileData?['display_name'] ?? 'Digital Minimalist',
        avatar: profileData?['avatar'] ?? '👤',
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load dashboard: $e',
      );
    }
  }

  Future<void> refresh() async {
    await loadDashboardData();
  }
}

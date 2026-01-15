import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/tracking_repository.dart';
import '../../data/repositories/reflection_repository.dart';
import '../../data/repositories/detox_repository.dart';

class ChartsState {
  final List<Map<String, dynamic>> usageHistory;
  final List<Map<String, dynamic>> moodHistory;
  final List<Map<String, dynamic>> detoxHistory; // ✅ ADDED: Detox stats
  final bool isLoading;

  ChartsState({
    this.usageHistory = const [],
    this.moodHistory = const [],
    this.detoxHistory = const [],
    this.isLoading = false,
  });

  ChartsState copyWith({
    List<Map<String, dynamic>>? usageHistory,
    List<Map<String, dynamic>>? moodHistory,
    List<Map<String, dynamic>>? detoxHistory,
    bool? isLoading,
  }) {
    return ChartsState(
      usageHistory: usageHistory ?? this.usageHistory,
      moodHistory: moodHistory ?? this.moodHistory,
      detoxHistory: detoxHistory ?? this.detoxHistory,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final chartsControllerProvider =
    StateNotifierProvider<ChartsController, ChartsState>((ref) {
      return ChartsController(
        ref.watch(trackingRepositoryProvider),
        ref.watch(reflectionRepositoryProvider),
        ref.watch(detoxRepositoryProvider), // ✅ ADDED
      );
    });

class ChartsController extends StateNotifier<ChartsState> {
  final TrackingRepository _trackingRepo;
  final ReflectionRepository _reflectionRepo;
  final DetoxRepository _detoxRepo;

  ChartsController(this._trackingRepo, this._reflectionRepo, this._detoxRepo)
    : super(ChartsState()) {
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true);

    try {
      // Parallel data fetching for performance
      final results = await Future.wait([
        _trackingRepo.getWeeklyUsageHistory(),
        _reflectionRepo.getReflectionHistory(days: 7),
        _detoxRepo
            .getSessionStats(), // You might need to add a history method to DetoxRepo
      ]);

      final usageHistory =
          (results[0] as List<dynamic>?)
              ?.map((e) => (e as Map).cast<String, dynamic>())
              .toList() ??
          <Map<String, dynamic>>[];

      final moodHistory =
          (results[1] as List<dynamic>?)
              ?.map((e) => (e as Map).cast<String, dynamic>())
              .toList() ??
          <Map<String, dynamic>>[];

      final detoxRaw = results[2];
      List<Map<String, dynamic>> detoxHistory = [];
      if (detoxRaw is List) {
        detoxHistory = detoxRaw
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();
      } else if (detoxRaw is Map) {
        detoxHistory = [(detoxRaw as Map).cast<String, dynamic>()];
      }

      state = state.copyWith(
        usageHistory: usageHistory,
        moodHistory: moodHistory,
        detoxHistory: detoxHistory,
        isLoading: false,
      );
    } catch (e) {
      print('Dashboard Load Error: $e');
      state = state.copyWith(isLoading: false);
    }
  }
}

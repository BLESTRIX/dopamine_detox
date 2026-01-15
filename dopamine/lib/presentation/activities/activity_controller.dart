import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/activity_repository.dart';
import '../../data/services/ai_service.dart';

// 1. STATE CLASS
class ActivityState {
  final List<Map<String, dynamic>> suggestions;
  final bool isLoading;
  final String selectedCategory;
  final bool isAiMode;
  final String? errorMessage;
  final List<String> categories;

  ActivityState({
    this.suggestions = const [],
    this.isLoading = false,
    this.selectedCategory = 'Mindful',
    this.isAiMode = false,
    this.errorMessage,
    this.categories = const [],
  });

  ActivityState copyWith({
    List<Map<String, dynamic>>? suggestions,
    bool? isLoading,
    String? selectedCategory,
    bool? isAiMode,
    String? errorMessage,
    List<String>? categories,
  }) {
    return ActivityState(
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isAiMode: isAiMode ?? this.isAiMode,
      errorMessage: errorMessage,
      categories: categories ?? this.categories,
    );
  }
}

// 2. DEFINE PROVIDERS
// We need the AI Service Provider available here
final aiServiceProvider = Provider<AIService>((ref) => AIService());

final activityControllerProvider =
    StateNotifierProvider<ActivityController, ActivityState>((ref) {
      // Inject BOTH Repository (Database) and AI Service (Gemini)
      return ActivityController(
        ref.watch(activityRepositoryProvider),
        ref.watch(aiServiceProvider),
      );
    });

// 3. CONTROLLER CLASS
class ActivityController extends StateNotifier<ActivityState> {
  final ActivityRepository _repository;
  final AIService _aiService; // ✅ Added AI Service

  ActivityController(this._repository, this._aiService)
    : super(ActivityState()) {
    _init();
  }

  Future<void> _init() async {
    await loadCategories();
    final initialCategory = state.categories.isNotEmpty
        ? state.categories.first
        : 'Mindful';
    fetchSuggestions(initialCategory);
  }

  /// Load categories from Database
  Future<void> loadCategories() async {
    try {
      final cats = await _repository.getAllCategories();
      state = state.copyWith(categories: cats);
    } catch (e) {
      // Fallback defaults
      state = state.copyWith(
        categories: ['Mindful', 'Physical', 'Creative', 'Educational'],
      );
    }
  }

  /// Fetch Static Suggestions from Database
  Future<void> fetchSuggestions(String category) async {
    state = state.copyWith(
      isLoading: true,
      selectedCategory: category,
      isAiMode: false,
      errorMessage: null,
    );

    try {
      final data = await _repository.getActivitiesByCategory(category);
      state = state.copyWith(suggestions: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load activities.',
      );
    }
  }

  /// Fetch AI Suggestions (Uses AIService directly now)
  Future<void> fetchAiSuggestions({
    required String mood,
    String? category,
  }) async {
    state = state.copyWith(isLoading: true, isAiMode: true, errorMessage: null);

    try {
      // ✅ FIX: Use _aiService instead of _repository
      // We pass the mood and a prompt about the category
      final targetCategory = category ?? state.selectedCategory;
      final result = await _aiService.suggestActivity(
        mood,
        "I am looking for a $targetCategory activity.",
      );

      if (result != null) {
        // Convert the single result into a List for the UI
        final List<Map<String, dynamic>> aiList = [
          {
            'id': 'ai_${DateTime.now().millisecondsSinceEpoch}',
            'title': result['activity'],
            'description': 'AI Suggested for $mood',
            'category': result['category'],
            'estimated_duration_minutes': 15, // Default duration
          },
        ];
        state = state.copyWith(suggestions: aiList, isLoading: false);
      } else {
        throw Exception("No suggestion returned");
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'AI unavailable. Showing static suggestions.',
      );
      // Fallback
      fetchSuggestions(state.selectedCategory);
    }
  }

  /// Log Activity Completion
  Future<void> completeActivity(String activityId, int minutes) async {
    try {
      await _repository.logActivityCompletion(
        activityId: activityId,
        durationMinutes: minutes,
      );
    } catch (e) {
      print('Error completing activity: $e');
    }
  }
}

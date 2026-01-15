import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/activity_repository.dart';

// ✅ The Provider Definition
// This allows UI screens to find this provider using "ref.watch(activityLogProvider)"
final activityLogProvider = ChangeNotifierProvider<ActivityProvider>((ref) {
  // We inject the repository so we can save/fetch real data
  final repo = ref.watch(activityRepositoryProvider);
  return ActivityProvider(repo);
});

class ActivityProvider with ChangeNotifier {
  final ActivityRepository _repository;

  // Store logs in memory for the UI to show immediately
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = false;

  ActivityProvider(this._repository);

  // Getters
  List<Map<String, dynamic>> get logs => _logs;
  bool get isLoading => _isLoading;

  /// Loads the user's history from Supabase
  Future<void> loadActivities() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch data from the repository
      final history = await _repository.getActivityHistory();

      // 2. Transform Supabase data into a flat structure for the UI
      _logs = history.map((item) {
        // Handle joined data safely
        final activity = item['activities'] as Map<String, dynamic>? ?? {};

        return {
          'title': activity['title'] ?? 'Unknown Activity',
          'category': activity['category'] ?? 'General',
          'date': DateTime.parse(item['completed_at']),
        };
      }).toList();
    } catch (e) {
      print("Provider Load Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new activity (from Manual Add or AI Suggestion)
  Future<void> addActivity(String title, String category) async {
    try {
      // 1. Save to DB (This creates the activity if new, then logs it)
      await _repository.logCustomActivity(title: title, category: category);

      // 2. Reload the list so the UI updates immediately
      await loadActivities();
    } catch (e) {
      print("Provider Add Error: $e");
      rethrow; // Pass error up so the UI can show a SnackBar
    }
  }
}

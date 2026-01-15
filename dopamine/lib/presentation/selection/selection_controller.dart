import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/detox_repository.dart';
import '../../data/services/app_tracking_service.dart';
import '../detox/detox_controller.dart';

// Simple model for the UI
class InstalledApp {
  final String appName;
  final String packageName;
  final int opensToday; // number of times opened in last 24h
  final int durationSeconds; // total foreground time in seconds (last 24h)

  InstalledApp({
    required this.appName,
    required this.packageName,
    this.opensToday = 0,
    this.durationSeconds = 0,
  });
}

class SelectionState {
  final List<InstalledApp> installedApps;
  final bool isLoading;
  final bool isStarting;
  final String? errorMessage;

  const SelectionState({
    this.installedApps = const [],
    this.isLoading = false,
    this.isStarting = false,
    this.errorMessage,
  });

  SelectionState copyWith({
    List<InstalledApp>? installedApps,
    bool? isLoading,
    bool? isStarting,
    String? errorMessage,
  }) {
    return SelectionState(
      installedApps: installedApps ?? this.installedApps,
      isLoading: isLoading ?? this.isLoading,
      isStarting: isStarting ?? this.isStarting,
      errorMessage: errorMessage,
    );
  }
}

final selectionControllerProvider =
    StateNotifierProvider<SelectionController, SelectionState>((ref) {
      return SelectionController(
        ref,
        ref.watch(detoxRepositoryProvider),
        ref.watch(appTrackingServiceProvider),
      );
    });

class SelectionController extends StateNotifier<SelectionState> {
  final Ref _ref;
  final DetoxRepository _detoxRepo;
  final AppTrackingService _trackingService;

  SelectionController(this._ref, this._detoxRepo, this._trackingService)
    : super(const SelectionState());

  Future<void> loadInstalledApps() async {
    state = state.copyWith(isLoading: true);
    try {
      // In a real app, this calls Platform Channel to get actual installed apps.
      // We simulate a list of common distracting apps for the assignment.
      await Future.delayed(const Duration(milliseconds: 500));

      final mockApps = [
        InstalledApp(
          appName: 'Instagram',
          packageName: 'com.instagram.android',
        ),
        InstalledApp(
          appName: 'TikTok',
          packageName: 'com.zhiliaoapp.musically',
        ),
        InstalledApp(appName: 'Facebook', packageName: 'com.facebook.katana'),
        InstalledApp(
          appName: 'Twitter / X',
          packageName: 'com.twitter.android',
        ),
        InstalledApp(
          appName: 'YouTube',
          packageName: 'com.google.android.youtube',
        ),
        InstalledApp(appName: 'Snapchat', packageName: 'com.snapchat.android'),
        InstalledApp(
          appName: 'Netflix',
          packageName: 'com.netflix.mediaclient',
        ),
        InstalledApp(appName: 'Reddit', packageName: 'com.reddit.frontpage'),
      ];

      // Fetch usage stats for each app in parallel. Falls back to 0s if unavailable.
      final enriched = await Future.wait(
        mockApps.map((a) async {
          try {
            final stats = await _trackingService.getUsageStats(a.packageName);
            final durationMs = (stats['duration'] ?? 0) as int;
            final opens = (stats['opens'] ?? 0) as int;
            return InstalledApp(
              appName: a.appName,
              packageName: a.packageName,
              opensToday: opens,
              durationSeconds: (durationMs / 1000).round(),
            );
          } catch (_) {
            return InstalledApp(appName: a.appName, packageName: a.packageName);
          }
        }).toList(),
      );

      state = state.copyWith(installedApps: enriched, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> requestPermission() async {
    // Call the service to request Android Usage Stats permission
    await _trackingService.checkPermission();
    // Reload apps after permission might be granted
    await loadInstalledApps();
  }

  Future<String?> startDetoxSession({
    required int durationMinutes,
    required List<String> restrictedApps,
  }) async {
    state = state.copyWith(isStarting: true);
    try {
      final sessionData = await _detoxRepo.startSession(
        durationMinutes: durationMinutes,
        restrictedApps: restrictedApps,
      );

      // Notify Detox timer controller to initialize local timer immediately
      try {
        _ref
            .read(detoxTimerControllerProvider.notifier)
            .setSessionFromMap(sessionData);
      } catch (_) {
        // ignore if timer controller not available for some reason
      }

      state = state.copyWith(isStarting: false);
      return sessionData['id']; // Return session ID for navigation
    } catch (e) {
      state = state.copyWith(isStarting: false, errorMessage: e.toString());
      return null;
    }
  }
}

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/detox_repository.dart';
import '../../data/repositories/streak_repository.dart';
import '../../domain/entities/detox_session.dart';

class DetoxTimerState {
  final int remainingSeconds;
  final bool isActive;
  final bool isPaused;
  final String? sessionId;
  final DetoxSession? session;
  final String? errorMessage;

  DetoxTimerState({
    this.remainingSeconds = 0,
    this.isActive = false,
    this.isPaused = false,
    this.sessionId,
    this.session,
    this.errorMessage,
  });

  DetoxTimerState copyWith({
    int? remainingSeconds,
    bool? isActive,
    bool? isPaused,
    String? sessionId,
    DetoxSession? session,
    String? errorMessage,
  }) {
    return DetoxTimerState(
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isActive: isActive ?? this.isActive,
      isPaused: isPaused ?? this.isPaused,
      sessionId: sessionId ?? this.sessionId,
      session: session ?? this.session,
      errorMessage: errorMessage,
    );
  }

  // Progress getter (0.0 to 1.0)
  double get progress {
    if (session == null || session!.targetDurationMinutes == 0) return 0.0;
    final totalSeconds = (session!.targetDurationMinutes * 60).toDouble();
    final elapsed = (totalSeconds - remainingSeconds).toDouble();
    // Return elapsed fraction (starts at 0.0, increases to 1.0)
    return (elapsed / totalSeconds).clamp(0.0, 1.0);
  }

  // Check if pause has been used
  bool get hasUsedPause {
    // Assuming logic: if pauseCount > 0, the user has used their one allowed pause
    return (session?.pauseCount ?? 0) > 0;
  }

  // Formatted time getter
  String get formattedTime {
    if (session != null) return session!.formattedRemainingTime;

    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

final detoxTimerControllerProvider =
    StateNotifierProvider<DetoxTimerController, DetoxTimerState>((ref) {
      return DetoxTimerController(
        ref.watch(detoxRepositoryProvider),
        ref.watch(streakRepositoryProvider),
      );
    });

class DetoxTimerController extends StateNotifier<DetoxTimerState> {
  final DetoxRepository _detoxRepo;
  final StreakRepository _streakRepo;
  Timer? _timer;

  DetoxTimerController(this._detoxRepo, this._streakRepo)
    : super(DetoxTimerState()) {
    _recoverActiveSession();
  }

  Future<void> _recoverActiveSession() async {
    try {
      final sessionMap = await _detoxRepo.getActiveSession();
      if (sessionMap == null) return;

      final session = DetoxSession.fromMap(sessionMap);
      if (session.isExpired) {
        await _completeSession(session.id);
      } else {
        // Calculate remaining seconds using UTC to avoid timezone mismatches
        final totalSeconds = session.targetDurationMinutes * 60;

        final now = DateTime.now().toUtc();
        final startTimeUtc = session.startTime.isUtc
            ? session.startTime
            : session.startTime.toUtc();
        final endTimeUtc = startTimeUtc.add(
          Duration(minutes: session.targetDurationMinutes),
        );

        var rem = endTimeUtc.difference(now).inSeconds;

        // Defensive: if remaining exceeds total (bad start_time), clamp to total
        if (rem > totalSeconds) rem = totalSeconds;

        state = state.copyWith(
          isActive: true,
          sessionId: session.id,
          session: session,
          remainingSeconds: rem > 0 ? rem : 0,
        );
        if (state.remainingSeconds > 0) _startTimer();
      }
    } catch (e) {
      print("Recovery Error: $e");
    }
  }

  Future<void> startSession(int minutes, List<String> apps) async {
    try {
      final sessionMap = await _detoxRepo.startSession(
        durationMinutes: minutes,
        restrictedApps: apps,
      );
      final session = DetoxSession.fromMap(sessionMap);

      state = state.copyWith(
        isActive: true,
        // Use full duration initially to avoid jumpiness, timer will correct it in <1s
        remainingSeconds: minutes * 60,
        sessionId: session.id,
        session: session,
        errorMessage: null,
      );
      _startTimer();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Start failed: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isPaused || state.session == null) return;

      final session = state.session!;

      // ✅ FIX: Convert both times to UTC to compare correctly
      final now = DateTime.now().toUtc();

      // Ensure session start time is treated as UTC
      final startTimeUtc = session.startTime.isUtc
          ? session.startTime
          : session.startTime.toUtc();

      final endTimeUtc = startTimeUtc.add(
        Duration(minutes: session.targetDurationMinutes),
      );

      // Calculate remaining seconds
      final diff = endTimeUtc.difference(now).inSeconds;

      if (diff > 0) {
        // Only update if value changed (optimization)
        if (state.remainingSeconds != diff) {
          state = state.copyWith(remainingSeconds: diff);
        }
      } else {
        // Timer finished
        state = state.copyWith(remainingSeconds: 0);
        _completeSession(state.sessionId!);
      }
    });
  }

  Future<void> togglePause() async {
    if (state.sessionId == null) return;
    try {
      if (state.isPaused) {
        await _detoxRepo.resumeSession(state.sessionId!);
        state = state.copyWith(isPaused: false);
      } else {
        // This checks backend rules (max 1 pause)
        await _detoxRepo.pauseSession(state.sessionId!);

        // Update local session state to reflect incremented pause count
        final updatedSession = state.session?.copyWith(
          pauseCount: (state.session?.pauseCount ?? 0) + 1,
        );

        state = state.copyWith(isPaused: true, session: updatedSession);
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Cannot pause: ${e.toString()}');
    }
  }

  Future<void> cancelSession() async {
    if (state.sessionId == null) return;
    _timer?.cancel();
    try {
      await _detoxRepo.updateSessionStatus(state.sessionId!, 'cancelled');
      state = DetoxTimerState(); // Reset state to initial
    } catch (e) {
      state = state.copyWith(errorMessage: 'Cancel failed: $e');
    }
  }

  Future<void> _completeSession(String sessionId) async {
    _timer?.cancel();
    try {
      await _detoxRepo.updateSessionStatus(sessionId, 'completed');
      await _streakRepo.incrementStreak();
      state = DetoxTimerState(); // Reset
    } catch (e) {
      state = state.copyWith(errorMessage: "Completion Error: $e");
    }
  }

  /// Accepts a session map (from server) and initializes local session state
  Future<void> setSessionFromMap(Map<String, dynamic> map) async {
    try {
      final session = DetoxSession.fromMap(map);

      final now = DateTime.now().toUtc();
      final startTimeUtc = session.startTime.isUtc
          ? session.startTime
          : session.startTime.toUtc();
      final endTimeUtc = startTimeUtc.add(
        Duration(minutes: session.targetDurationMinutes),
      );

      var rem = endTimeUtc.difference(now).inSeconds;

      // Sanity check
      final totalSeconds = session.targetDurationMinutes * 60;
      if (rem > totalSeconds) rem = totalSeconds;

      state = state.copyWith(
        isActive: true,
        sessionId: session.id,
        session: session,
        remainingSeconds: rem > 0 ? rem : 0,
        isPaused: false,
      );

      if (state.remainingSeconds > 0) _startTimer();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to set session: $e');
    }
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

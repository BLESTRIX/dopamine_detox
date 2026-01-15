enum DetoxStatus { active, completed, failed, cancelled }

class DetoxSession {
  final String id;
  final DateTime startTime;
  final int targetDurationMinutes;
  final DetoxStatus status;
  final int pauseCount;
  final List<String> restrictedApps;
  final DateTime? endTime; // ✅ ADDED
  final Map<String, dynamic>? metadata; // ✅ ADDED: Store full metadata

  DetoxSession({
    required this.id,
    required this.startTime,
    required this.targetDurationMinutes,
    required this.status,
    this.pauseCount = 0,
    this.restrictedApps = const [],
    this.endTime,
    this.metadata,
  });

  // Business Logic: Calculate if the session should be over
  bool get isExpired {
    final expiryTime = startTime.add(Duration(minutes: targetDurationMinutes));
    return DateTime.now().isAfter(expiryTime);
  }

  // Business Logic: Calculate progress percentage for the UI ring
  double get progress {
    final elapsed = DateTime.now().difference(startTime).inSeconds;
    final total = targetDurationMinutes * 60;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  // ✅ ADDED: Calculate remaining time
  Duration get remainingTime {
    final now = DateTime.now();
    // Defensive: if startTime is in the future (bad data or timezone issue),
    // treat the effective start as `now` so the session appears to start immediately.
    final effectiveStart = startTime.isAfter(now) ? now : startTime;
    final expiryTime = effectiveStart.add(
      Duration(minutes: targetDurationMinutes),
    );
    final remaining = expiryTime.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  // ✅ ADDED: Format remaining time
  String get formattedRemainingTime {
    final hours = remainingTime.inHours;
    final minutes = remainingTime.inMinutes.remainder(60);
    final seconds = remainingTime.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  // ✅ ADDED: Check if pause is allowed (business rule: max 1 pause)
  bool get canPause {
    return pauseCount < 1 && status == DetoxStatus.active;
  }

  // ✅ ADDED: Get session duration (actual time spent)
  Duration get actualDuration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return DateTime.now().difference(startTime);
  }

  // Convert Supabase Map to Entity
  factory DetoxSession.fromMap(Map<String, dynamic> map) {
    // ✅ FIXED: Extract restricted apps from metadata JSONB column
    final metadata = map['metadata'] as Map<String, dynamic>?;
    final apps = metadata?['restricted_apps'] as List<dynamic>?;
    final restrictedApps = apps?.map((e) => e.toString()).toList() ?? [];

    return DetoxSession(
      id: map['id'],
      startTime: DateTime.parse(map['start_time']),
      targetDurationMinutes: map['target_duration_minutes'],
      status: _parseStatus(map['status']),
      pauseCount: map['pause_count'] ?? 0,
      restrictedApps: restrictedApps,
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : null,
      metadata: metadata,
    );
  }

  // ✅ ADDED: Helper to parse status string to enum
  static DetoxStatus _parseStatus(String? status) {
    switch (status) {
      case 'active':
        return DetoxStatus.active;
      case 'completed':
        return DetoxStatus.completed;
      case 'failed':
        return DetoxStatus.failed;
      case 'cancelled':
        return DetoxStatus.cancelled;
      default:
        return DetoxStatus.active;
    }
  }

  // ✅ ADDED: Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'target_duration_minutes': targetDurationMinutes,
      'status': status.name,
      'pause_count': pauseCount,
      'end_time': endTime?.toIso8601String(),
      'metadata': {'restricted_apps': restrictedApps, ...?metadata},
    };
  }

  // ✅ ADDED: Copy with method
  DetoxSession copyWith({
    String? id,
    DateTime? startTime,
    int? targetDurationMinutes,
    DetoxStatus? status,
    int? pauseCount,
    List<String>? restrictedApps,
    DateTime? endTime,
    Map<String, dynamic>? metadata,
  }) {
    return DetoxSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      targetDurationMinutes:
          targetDurationMinutes ?? this.targetDurationMinutes,
      status: status ?? this.status,
      pauseCount: pauseCount ?? this.pauseCount,
      restrictedApps: restrictedApps ?? this.restrictedApps,
      endTime: endTime ?? this.endTime,
      metadata: metadata ?? this.metadata,
    );
  }
}

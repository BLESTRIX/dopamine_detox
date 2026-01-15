class AppUsage {
  final String packageName;
  final Duration totalTime;
  final int openCount;
  final DateTime date;

  AppUsage({
    required this.packageName,
    required this.totalTime,
    required this.openCount,
    required this.date,
  });

  // ✅ FIXED: Updated to match correct column names
  factory AppUsage.fromMap(Map<String, dynamic> map) {
    return AppUsage(
      packageName: map['app_package_name'], // ✅ FIXED: Was 'package_name'
      totalTime: Duration(
        seconds: map['duration_seconds'] ?? 0,
      ), // ✅ FIXED: Was 'total_time_seconds'
      openCount: map['opens_count'] ?? 0, // ✅ FIXED: Was 'open_count'
      date: DateTime.parse(map['log_date']), // ✅ FIXED: Was 'usage_date'
    );
  }

  // ✅ ADDED: Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'app_package_name': packageName,
      'duration_seconds': totalTime.inSeconds,
      'opens_count': openCount,
      'log_date': date.toIso8601String().split('T')[0],
    };
  }

  // ✅ ADDED: Get display name from package name
  String get displayName {
    // Extract app name from package (e.g., 'com.instagram.android' → 'Instagram')
    final parts = packageName.split('.');
    if (parts.isEmpty) return packageName;

    final name = parts.last;
    // Capitalize first letter
    return name[0].toUpperCase() + name.substring(1);
  }

  // ✅ ADDED: Format duration for display
  String get formattedDuration {
    final hours = totalTime.inHours;
    final minutes = totalTime.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '${totalTime.inSeconds}s';
    }
  }

  // ✅ ADDED: Calculate average session duration
  Duration get avgSessionDuration {
    if (openCount == 0) return Duration.zero;
    return Duration(seconds: totalTime.inSeconds ~/ openCount);
  }

  // ✅ ADDED: Copy with method for updates
  AppUsage copyWith({
    String? packageName,
    Duration? totalTime,
    int? openCount,
    DateTime? date,
  }) {
    return AppUsage(
      packageName: packageName ?? this.packageName,
      totalTime: totalTime ?? this.totalTime,
      openCount: openCount ?? this.openCount,
      date: date ?? this.date,
    );
  }
}

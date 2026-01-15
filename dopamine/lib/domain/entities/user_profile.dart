class UserProfile {
  final String id;
  final String userId;
  final String? displayName;
  final String? avatar; // ✅ ADDED: Avatar field
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastStreakUpdate;

  UserProfile({
    required this.id,
    required this.userId,
    this.displayName,
    this.avatar, // ✅ ADDED
    required this.currentStreak,
    required this.longestStreak,
    this.lastStreakUpdate,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      userId: map['user_id'],
      displayName: map['display_name'],
      avatar: map['avatar'], // ✅ ADDED
      currentStreak: map['current_streak'] ?? 0,
      longestStreak: map['longest_streak'] ?? 0,
      lastStreakUpdate: map['last_streak_update'] != null
          ? DateTime.parse(map['last_streak_update'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'display_name': displayName,
      'avatar': avatar, // ✅ ADDED
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_streak_update': lastStreakUpdate?.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? userId,
    String? displayName,
    String? avatar, // ✅ ADDED
    int? currentStreak,
    int? longestStreak,
    DateTime? lastStreakUpdate,
  }) {
    return UserProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar, // ✅ ADDED
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastStreakUpdate: lastStreakUpdate ?? this.lastStreakUpdate,
    );
  }
}

import 'package:flutter/material.dart';

class Reflection {
  final DateTime date;
  final String moodKey;           // ✅ ADDED: "Calm", "Focused", etc.
  final String moodEmoji;         // ✅ ADDED: "😌", "🧠", etc.
  final String? text;
  final int? energyLevel;         // ✅ ADDED: 1-5 energy rating

  Reflection({
    required this.date,
    required this.moodKey,
    required this.moodEmoji,
    this.text,
    this.energyLevel,
  });

  factory Reflection.fromMap(Map<String, dynamic> map) {
    return Reflection(
      date: DateTime.parse(map['log_date']),
      moodKey: map['mood_key'],               // ✅ FIXED: Added
      moodEmoji: map['mood_emoji'],           // ✅ FIXED: Added
      text: map['reflection_text'],           // ✅ FIXED: Changed from journal_text
      energyLevel: map['energy_level'],       // ✅ FIXED: Added
    );
  }
  
  // ✅ ADDED: Helper to get color based on mood
  Color get moodColor {
    switch (moodKey) {
      case 'Calm':
        return const Color(0xFFA8E6CF); // Soft green
      case 'Focused':
        return const Color(0xFF81C3D7); // Soft blue
      case 'Proud':
        return const Color(0xFFFFD93D); // Yellow
      case 'Restless':
        return const Color(0xFFFFB6B9); // Soft red
      case 'Anxious':
        return const Color(0xFFD4A5A5); // Muted red
      default:
        return Colors.grey;
    }
  }
}
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'dart:ui';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tzdata.initializeTimeZones();

    // Android Settings (ensure 'ic_launcher' exists in res/drawable)
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS Settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
  }

  /// 1. Gamification: Immediate notification for Badge Earned
  Future<void> showBadgeNotification(String badgeName) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'gamification_channel',
          'Achievements',
          channelDescription: 'Notifications for earned badges',
          importance: Importance.max,
          priority: Priority.high,
          color: Color(0xFFA8E6CF), // Soft Green (App Theme)
        );

    await _notifications.show(
      1,
      'New Achievement Unlocked! 🏆',
      'Congratulations! You earned the "$badgeName" badge.',
      const NotificationDetails(android: androidDetails),
    );
  }

  /// 2. Retention: Schedules a daily Reflection prompt
  Future<void> scheduleDailyReflection(int hour, int minute) async {
    await _notifications.zonedSchedule(
      2,
      'Time to Reflect 📝',
      'How was your focus today? Take a moment to log your mood.',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reflection_channel',
          'Daily Reminders',
          importance: Importance.defaultImportance,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeats daily
    );
  }

  /// 3. Smart Reminder: Remind user to start a detox if they haven't yet
  Future<void> scheduleDetoxReminder(int hour, int minute) async {
    await _notifications.zonedSchedule(
      3,
      'Digital Detox Reminder 📵',
      'Ready to disconnect? Start your scheduled detox session now.',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'detox_reminders',
          'Detox Sessions',
          importance: Importance.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}

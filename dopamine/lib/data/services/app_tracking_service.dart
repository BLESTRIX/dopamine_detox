import 'package:flutter/foundation.dart'; // ✅ Required for kIsWeb
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

final appTrackingServiceProvider = Provider<AppTrackingService>((ref) {
  return AppTrackingService();
});

class AppTrackingService {
  static const platform = MethodChannel('com.detox.app/usage');

  Future<bool> checkPermission() async {
    // ✅ Fix: Return true (or false) immediately on Web to avoid crash
    if (kIsWeb) return true;

    if (!Platform.isAndroid) return true;
    try {
      final bool hasPermission = await platform.invokeMethod(
        'hasUsagePermission',
      );
      return hasPermission;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getUsageStats(String packageName) async {
    // ✅ Fix: Check Web first
    if (kIsWeb) return {'duration': 0, 'opens': 0};

    if (!Platform.isAndroid) return {'duration': 0, 'opens': 0};

    try {
      final Map<dynamic, dynamic> stats = await platform
          .invokeMethod('getUsageStats', {
            'packageName': packageName,
            'startTime': DateTime.now()
                .subtract(const Duration(days: 1))
                .millisecondsSinceEpoch,
            'endTime': DateTime.now().millisecondsSinceEpoch,
          });

      return {
        'duration': stats['totalTimeInForeground'] ?? 0,
        'opens': stats['appOpenCount'] ?? 0,
      };
    } on PlatformException catch (_) {
      return {'duration': 0, 'opens': 0};
    }
  }
}

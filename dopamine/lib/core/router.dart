import 'package:flutter/material.dart';
import '../presentation/auth/auth_screen.dart';
import '../presentation/navigation_wrapper.dart'; // ✅ Import NavigationWrapper
import '../presentation/detox/detox_timer_screen.dart';
import '../presentation/selection/selection_screen.dart';
import '../presentation/activities/activity_suggestion_screen.dart';
import '../presentation/reflection/reflection_screen.dart';
import '../presentation/badges/badges_screen.dart';
import '../presentation/profile/profile_screen.dart';
import '../presentation/dashboard/charts_view.dart';

class AppRouter {
  static const String home = '/';
  static const String auth = '/auth';
  static const String selection = '/selection';
  static const String detoxTimer = '/detoxTimer';
  static const String activities = '/activities';
  static const String reflection = '/reflection';
  static const String badges = '/badges';
  static const String profile = '/profile';
  static const String charts = '/charts';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        // ✅ CHANGED: Point to NavigationWrapper instead of HomeScreen
        return _buildRoute(const NavigationWrapper());

      case auth:
        return _buildRoute(const AuthScreen());

      case selection:
        return _buildRoute(const SelectionScreen());

      case detoxTimer:
        return _buildRoute(
          const DetoxTimerScreen(),
        ); // Pass sessionId if needed

      case activities:
        return _buildRoute(const ActivitySuggestionScreen());

      case reflection:
        return _buildRoute(const ReflectionScreen());

      case badges:
        return _buildRoute(const BadgesScreen());

      case profile:
        return _buildRoute(const ProfileScreen());

      case charts:
        return _buildRoute(const ChartsView());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }

  static MaterialPageRoute _buildRoute(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }

  // Helper Navigation Methods
  static Future<void> toHome(BuildContext context) {
    // Uses pushReplacement so user can't "back" into Auth
    return Navigator.pushReplacementNamed(context, home);
  }

  static Future<void> toAuth(BuildContext context) {
    return Navigator.pushReplacementNamed(context, auth);
  }

  static Future<void> toSelection(BuildContext context) {
    return Navigator.pushNamed(context, selection);
  }

  static Future<void> toDetoxTimer(
    BuildContext context, {
    String? sessionId,
    bool replace = false,
  }) {
    if (replace) {
      return Navigator.pushReplacementNamed(
        context,
        detoxTimer,
        arguments: sessionId,
      );
    }
    return Navigator.pushNamed(context, detoxTimer, arguments: sessionId);
  }

  static Future<void> toActivities(BuildContext context) {
    return Navigator.pushNamed(context, activities);
  }

  static Future<void> toReflection(BuildContext context) {
    return Navigator.pushNamed(context, reflection);
  }

  static Future<void> toBadges(BuildContext context) {
    return Navigator.pushNamed(context, badges);
  }

  static Future<void> toProfile(BuildContext context) {
    return Navigator.pushNamed(context, profile);
  }

  static Future<void> toCharts(BuildContext context) {
    return Navigator.pushNamed(context, charts);
  }
}

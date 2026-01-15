import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/supabase_client.dart';
import 'core/router.dart';
import 'presentation/theme/app_theme.dart'; // Import the new theme file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();
  runApp(const ProviderScope(child: DopamineDetoxApp()));
}

class DopamineDetoxApp extends ConsumerWidget {
  const DopamineDetoxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);

    // Select the correct theme data based on the controller state
    ThemeData activeTheme;
    switch (themeMode) {
      case AppThemeMode.focusBlue:
        activeTheme = AppTheme.focusBlue;
        break;
      case AppThemeMode.sunsetOrange:
        activeTheme = AppTheme.sunsetOrange;
        break;
      case AppThemeMode.calmGreen:
        activeTheme = AppTheme.calmGreen;
        break;
    }

    return MaterialApp(
      title: 'Dopamine Detox',
      debugShowCheckedModeBanner: false,
      theme: activeTheme,
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: AppRouter.home,
    );
  }
}

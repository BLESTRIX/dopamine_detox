import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/router.dart';
import 'selection_controller.dart';

class SelectionScreen extends ConsumerStatefulWidget {
  const SelectionScreen({super.key});

  @override
  ConsumerState<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends ConsumerState<SelectionScreen> {
  final Set<String> selectedApps = {};
  int selectedDuration = 60; // Default 60 minutes

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(selectionControllerProvider.notifier).loadInstalledApps();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(selectionControllerProvider);
    final theme = Theme.of(context);

    Widget bodyContent;

    if (state.isLoading) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (state.errorMessage != null) {
      bodyContent = _buildErrorState(state.errorMessage!);
    } else {
      bodyContent = Column(
        children: [
          _buildDurationSelector(theme),
          Expanded(
            child: state.installedApps.isEmpty
                ? _buildEmptyState()
                : _buildAppList(state.installedApps, theme),
          ),
          _buildBottomAction(context, theme),
        ],
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Select Apps to Block'),
        backgroundColor: theme.colorScheme.primaryContainer,
        elevation: 0,
      ),
      body: bodyContent,
    );
  }

  Widget _buildDurationSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: theme.cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Session Duration',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$selectedDuration minutes',
                  style: TextStyle(
                    fontSize: 32, // Made slightly larger
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: selectedDuration.toDouble(),
            min: 15,
            max: 180,
            divisions: 11,
            label: '$selectedDuration m',
            activeColor: theme.colorScheme.primary,
            onChanged: (value) {
              const step = 15;
              final nearest = ((value / step).round() * step);
              setState(() {
                selectedDuration = nearest;
              });
            },
          ),
          // ✅ REMOVED: The Row of Duration Chips (15m, 30m, etc.) is gone.
        ],
      ),
    );
  }

  Widget _buildAppList(List<InstalledApp> apps, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: apps.length,
      itemBuilder: (context, index) {
        final app = apps[index];
        final isSelected = selectedApps.contains(app.packageName);

        return CheckboxListTile(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              if (value == true) {
                selectedApps.add(app.packageName);
              } else {
                selectedApps.remove(app.packageName);
              }
            });
          },
          title: Text(
            app.appName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              Text(
                '${app.opensToday} opens • ${((app.durationSeconds) / 60).round()}m today',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          // ✅ UPDATED: Now uses branded app icons instead of generic generic icon
          secondary: _buildAppIcon(app.appName, app.packageName, theme),
          activeColor: theme.colorScheme.primary,
          controlAffinity: ListTileControlAffinity.trailing,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        );
      },
    );
  }

  // ✅ NEW HELPER: Creates a brand-colored avatar for the app
  Widget _buildAppIcon(String appName, String packageName, ThemeData theme) {
    Color bgColor;
    Color textColor = Colors.white;

    // Simple logic to match common apps to their brand colors
    // (Since we don't have the actual icon assets in this environment)
    final lowerName = appName.toLowerCase();
    if (lowerName.contains('instagram')) {
      bgColor = const Color(0xFFE1306C);
    } else if (lowerName.contains('facebook')) {
      bgColor = const Color(0xFF1877F2);
    } else if (lowerName.contains('twitter') || lowerName.contains(' x')) {
      bgColor = Colors.black;
    } else if (lowerName.contains('tiktok')) {
      bgColor = Colors.black;
      textColor = const Color(0xFF00F2EA); // Cyan accent for TikTok feel
    } else if (lowerName.contains('youtube')) {
      bgColor = const Color(0xFFFF0000);
    } else if (lowerName.contains('whatsapp')) {
      bgColor = const Color(0xFF25D366);
    } else if (lowerName.contains('snapchat')) {
      bgColor = const Color(0xFFFFFC00);
      textColor = Colors.black;
    } else if (lowerName.contains('netflix')) {
      bgColor = const Color(0xFFE50914);
    } else if (lowerName.contains('reddit')) {
      bgColor = const Color(0xFFFF4500);
    } else {
      // Default fallback
      bgColor = theme.colorScheme.primaryContainer;
      textColor = theme.colorScheme.primary;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          appName.isNotEmpty ? appName[0].toUpperCase() : '?',
          style: TextStyle(
            color: textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, ThemeData theme) {
    final isStarting = ref.watch(
      selectionControllerProvider.select((state) => state.isStarting),
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${selectedApps.length} apps selected',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (selectedApps.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedApps.clear();
                    });
                  },
                  child: const Text('Clear all'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedApps.isEmpty || isStarting
                  ? null
                  : () => _startDetoxSession(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isStarting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Start $selectedDuration-Min Detox',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startDetoxSession(BuildContext context) async {
    try {
      final sessionId = await ref
          .read(selectionControllerProvider.notifier)
          .startDetoxSession(
            durationMinutes: selectedDuration,
            restrictedApps: selectedApps.toList(),
          );

      if (sessionId != null && context.mounted) {
        await AppRouter.toDetoxTimer(
          context,
          sessionId: sessionId,
          replace: true,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.apps, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No apps found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Grant usage access permission to see installed apps',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(selectionControllerProvider.notifier)
                  .requestPermission();
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading apps',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(selectionControllerProvider.notifier)
                  .loadInstalledApps();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

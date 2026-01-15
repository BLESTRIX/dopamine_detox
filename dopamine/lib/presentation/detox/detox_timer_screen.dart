import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'detox_controller.dart';

class DetoxTimerScreen extends ConsumerWidget {
  const DetoxTimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(detoxTimerControllerProvider);
    final theme = Theme.of(context);

    // ✅ FIXED: SnackBar Logic
    // Listen to state changes to show SnackBar only when error changes/appears
    ref.listen<DetoxTimerState>(detoxTimerControllerProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: theme.colorScheme.error,
          ),
        );
        // Clear the error immediately after showing
        ref.read(detoxTimerControllerProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Deep Focus',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              if (state.session != null)
                Text(
                  '${state.session!.targetDurationMinutes} minute session',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              const SizedBox(height: 40),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: CircularProgressIndicator(
                      // ✅ FIXED: usage of state.progress
                      value: state.progress,
                      strokeWidth: 8,
                      // ✅ FIXED: Dynamic colors
                      color: theme.colorScheme.primary,
                      backgroundColor: theme.colorScheme.surfaceVariant,
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        // ✅ FIXED: usage of state.formattedTime
                        state.formattedTime,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      if (state.isPaused)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: .2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'PAUSED',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 60),
              if (state.session != null &&
                  state.session!.restrictedApps.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Avoiding ${state.session!.restrictedApps.length} apps',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              _buildPauseButton(context, ref, state),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => _showCancelDialog(context, ref),
                icon: Icon(Icons.close, color: theme.colorScheme.error),
                label: Text(
                  'Cancel Session',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPauseButton(
    BuildContext context,
    WidgetRef ref,
    DetoxTimerState state,
  ) {
    // ✅ FIXED: usage of state.hasUsedPause
    final isDisabled = state.hasUsedPause && !state.isPaused;
    final theme = Theme.of(context);

    return ElevatedButton.icon(
      onPressed: isDisabled
          ? null
          : () => ref.read(detoxTimerControllerProvider.notifier).togglePause(),
      icon: Icon(state.isPaused ? Icons.play_arrow : Icons.pause),
      label: Text(
        state.isPaused
            ? 'Resume'
            : state.hasUsedPause
            ? 'Pause Used'
            : 'Take a Break',
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled
            ? theme.disabledColor
            : theme.colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  Future<void> _showCancelDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Session?'),
        content: const Text('This will not count toward your streak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Session'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // ✅ FIXED: Calls the now implemented cancelSession method
      await ref.read(detoxTimerControllerProvider.notifier).cancelSession();
      if (context.mounted) Navigator.pop(context);
    }
  }
}

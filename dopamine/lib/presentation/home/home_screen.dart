import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/router.dart';
import 'home_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);
    final theme = Theme.of(context);

    // 1. Handle Loading State
    if (state.isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 2. Handle Error State
    if (state.errorMessage != null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text('Error: ${state.errorMessage}', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(homeControllerProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Handle Success/Content State
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(child: _buildContent(context, ref, state)),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, HomeState state) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(homeControllerProvider.notifier).refresh();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, state),
            const SizedBox(height: 20),
            _buildDetoxTimerCard(context, ref, state),
            const SizedBox(height: 24),
            _buildStreakCard(context, state),
            const SizedBox(height: 24),
            _buildActionCards(context, ref, state),
            const SizedBox(height: 24),
            _buildQuickStats(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, HomeState state) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back,',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              state.userName, // ✅ Dynamic Name
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => AppRouter.toProfile(context),
          // ✅ FIXED: Shows Avatar Emoji inside a styled circle
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                state.avatar, // ✅ Dynamic Emoji
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetoxTimerCard(
    BuildContext context,
    WidgetRef ref,
    HomeState state,
  ) {
    final theme = Theme.of(context);
    final hasActive = state.hasActiveSession;
    final reclaimed = state.totalMinutesReclaimed;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (hasActive)
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: null, // Indeterminate animation for "Active" state
                    strokeWidth: 10,
                    color: theme.colorScheme.primary,
                    backgroundColor: Colors.transparent,
                  ),
                )
              else
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                        border: Border.all(
                          color: theme.colorScheme.onSurface.withOpacity(0.06),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hasActive ? 'On Going' : 'Ready',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasActive ? 'Focus Session' : 'Detox Timer',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text(
                    '${reclaimed}m',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('Time Saved', style: TextStyle(color: Colors.grey[700])),
                ],
              ),
              Column(
                children: [
                  Text(
                    '${state.currentStreak}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Streak (days)',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // ✅ QUOTE SECTION
          if (state.quoteText != null && state.quoteText!.isNotEmpty)
            Column(
              children: [
                Text(
                  '"${state.quoteText!}"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 6),
                if (state.quoteAuthor != null)
                  Text(
                    '- ${state.quoteAuthor!}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
              ],
            )
          else
            Text(
              '"Discipline creates freedom."',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurface.withOpacity(0.85),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, HomeState state) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Streak',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${state.currentStreak} days',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Best: ${state.longestStreak} days',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards(
    BuildContext context,
    WidgetRef ref,
    HomeState state,
  ) {
    final theme = Theme.of(context);
    final tertiaryColor = theme.colorScheme.surfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildActionCard(
          context: context, // ✅ FIXED: Passed missing context
          title: state.hasActiveSession ? 'Resume Detox' : 'Start New Session',
          subtitle: state.hasActiveSession
              ? 'Continue your focus session'
              : 'Block distracting apps for 60 minutes',
          icon: state.hasActiveSession ? Icons.play_circle_filled : Icons.timer,
          color: theme.colorScheme.primary,
          onTap: () async {
            if (state.hasActiveSession) {
              await AppRouter.toDetoxTimer(context, replace: true);
            } else {
              await AppRouter.toSelection(context);
            }
          },
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          context: context, // ✅ FIXED: Passed missing context
          title: 'Daily Reflection',
          subtitle: 'How are you feeling today?',
          icon: Icons.edit_note,
          color: theme.colorScheme.secondary,
          onTap: () => AppRouter.toReflection(context),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          context: context, // ✅ FIXED: Passed missing context
          title: 'Find Activities',
          subtitle: 'Discover healthy replacement activities',
          icon: Icons.lightbulb_outline,
          color: tertiaryColor,
          onTap: () => AppRouter.toActivities(context),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          context: context, // ✅ FIXED: Passed missing context
          title: 'View Achievements',
          subtitle: 'Check your badges and milestones',
          icon: Icons.emoji_events,
          color: const Color(0xFFFFDAB9),
          onTap: () => AppRouter.toBadges(context),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context, // ✅ Added context parameter
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, HomeState state) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'This Week',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => AppRouter.toCharts(context),
              child: Text(
                'View Report',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Sessions',
                '${state.completedSessions}',
                Icons.check_circle_outline,
                theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Focus Time',
                '${state.totalMinutesReclaimed}m',
                Icons.timer_outlined,
                theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

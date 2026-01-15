import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_controller.dart';
import '../theme/app_theme.dart';
import '../../core/router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileControllerProvider);
    final themeMode = ref.watch(themeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        centerTitle: true,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildProfileHeader(state, context), // ✅ UPDATED
                  const SizedBox(height: 32),
                  _buildStatsRow(state),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Preferences'),
                  const SizedBox(height: 16),
                  _buildSettingsCard(context, ref, state, themeMode),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Account'),
                  const SizedBox(height: 16),
                  _buildAccountCard(context, ref),
                ],
              ),
            ),
    );
  }

  // ✅ UPDATED: Shows full avatar emoji
  Widget _buildProfileHeader(ProfileState state, BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.2),
              width: 3,
            ),
          ),
          child: Center(
            child: Text(
              state.avatar, // Use the stored emoji avatar
              style: const TextStyle(fontSize: 50),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          state.displayName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text('Digital Minimalist', style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  // ... (Rest of the file remains unchanged: _buildStatsRow, _buildSettingsCard, etc.) ...
  Widget _buildStatsRow(ProfileState state) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            '${state.totalDetoxMinutes ~/ 60}h ${state.totalDetoxMinutes % 60}m',
            'Total Focus',
            Icons.timer,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatItem(
            '${state.badgesEarned}',
            'Badges',
            Icons.emoji_events,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context,
    WidgetRef ref,
    ProfileState state,
    AppThemeMode currentTheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.track_changes),
            title: const Text('Daily Goal'),
            subtitle: Text('${state.dailyGoalMinutes} minutes'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showGoalDialog(context, ref, state.dailyGoalMinutes),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('App Theme'),
            trailing: DropdownButton<AppThemeMode>(
              value: currentTheme,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(
                  value: AppThemeMode.calmGreen,
                  child: Text('Calm Green'),
                ),
                DropdownMenuItem(
                  value: AppThemeMode.focusBlue,
                  child: Text('Focus Blue'),
                ),
                DropdownMenuItem(
                  value: AppThemeMode.sunsetOrange,
                  child: Text('Sunset Orange'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeControllerProvider.notifier).setTheme(value);
                }
              },
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            value: state.notificationsEnabled,
            activeColor: Theme.of(context).primaryColor,
            onChanged: (val) {
              ref
                  .read(profileControllerProvider.notifier)
                  .toggleNotifications(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text('Log Out', style: TextStyle(color: Colors.red)),
        onTap: () async {
          await ref.read(profileControllerProvider.notifier).signOut();
          if (context.mounted) {
            AppRouter.toHome(context);
          }
        },
      ),
    );
  }

  Future<void> _showGoalDialog(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) async {
    int selected = current;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Daily Goal'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$selected minutes'),
              Slider(
                min: 15,
                max: 180,
                divisions: 11,
                value: selected.toDouble(),
                onChanged: (val) => setState(() => selected = val.toInt()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(profileControllerProvider.notifier)
                  .updateDailyGoal(selected);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

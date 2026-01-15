import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'activity_controller.dart';

class ActivitySuggestionScreen extends ConsumerWidget {
  const ActivitySuggestionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityControllerProvider);
    final controller = ref.read(activityControllerProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Healthy Replacements')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (state.isAiMode) {
            controller.fetchSuggestions(state.selectedCategory);
          } else {
            // You can pass the actual user mood here if available
            controller.fetchAiSuggestions(mood: 'Bored');
          }
        },
        backgroundColor: theme.colorScheme.primaryContainer,
        icon: Icon(
          state.isAiMode ? Icons.auto_awesome : Icons.smart_toy_outlined,
          color: theme.colorScheme.primary,
        ),
        label: Text(
          state.isAiMode ? 'Switch to Classic' : 'Ask AI',
          style: TextStyle(color: theme.colorScheme.primary),
        ),
      ),
      body: Column(
        children: [
          // ---------------------------------------------------------
          // ✅ DYNAMIC CATEGORY LIST
          // ---------------------------------------------------------
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: state.categories.map((category) {
                final isSelected = state.selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    selectedColor: theme.colorScheme.primaryContainer,
                    checkmarkColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.black,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    onSelected: (bool selected) {
                      if (selected) controller.fetchSuggestions(category);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // ---------------------------------------------------------
          // ACTIVITY LIST
          // ---------------------------------------------------------
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.suggestions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.suggestions.length,
                    itemBuilder: (context, index) {
                      final activity = state.suggestions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.accessibility_new,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            activity['title'] ?? 'Activity',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(activity['description'] ?? ''),
                          onTap: () {
                            _showCompletionDialog(
                              context,
                              controller,
                              activity,
                              theme,
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No activities found for this category.",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog(
    BuildContext context,
    ActivityController controller,
    Map activity,
    ThemeData theme,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Complete "${activity['title']}"?'),
        content: const Text('Did you finish this activity?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.completeActivity(
                activity['id'],
                activity['estimated_duration_minutes'] ?? 15,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Activity Logged! Good job.")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, I did it!'),
          ),
        ],
      ),
    );
  }
}

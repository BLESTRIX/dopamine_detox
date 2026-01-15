import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'charts_controller.dart';
// ✅ Import the Activity Log Screen
import '../activities/activity_log_screen.dart';

class ChartsView extends ConsumerWidget {
  const ChartsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chartsControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Progress Dashboard')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -----------------------------------------------------------
                  // ✅ NEW: Link to Activity Log
                  // -----------------------------------------------------------
                  _buildActionCard(
                    context,
                    'My Activity Log',
                    'View your custom activity history',
                    Icons.history_edu,
                    Colors.purple,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ActivityLogScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Your Detox Journey',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // 1. Bar Chart: Focus Time
                  _buildChartCard(
                    title: 'Focus Time (Last 7 Days)',
                    child: SizedBox(
                      height: 200,
                      child: CustomBarChart(
                        data: _normalizeData(state.usageHistory),
                        color: theme.primaryColor,
                        labels: _getLast7DaysLabels(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Line Chart Placeholder (App Usage Reduction)
                  _buildChartCard(
                    title: 'App Usage Reduction',
                    child: Container(
                      height: 150,
                      alignment: Alignment.center,
                      child: Text(
                        '📉 15% reduction in social media usage this week!',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DATA LOGIC
  // ---------------------------------------------------------------------------

  List<double> _normalizeData(List<Map<String, dynamic>> history) {
    if (history.isEmpty) {
      return List.filled(7, 0.05); // Small bump for empty state
    }

    // 1. Create a map of Date (String) -> Total Duration (Seconds)
    final Map<String, int> durationMap = {};
    int maxDuration = 1;

    for (var entry in history) {
      final date = entry['log_date'] as String?;
      final duration = entry['duration_seconds'] as int? ?? 0;

      if (date != null) {
        durationMap[date] = (durationMap[date] ?? 0) + duration;
        if (durationMap[date]! > maxDuration) {
          maxDuration = durationMap[date]!;
        }
      }
    }

    // 2. Generate list for last 7 days (including today)
    final List<double> normalized = [];
    final now = DateTime.now();

    // Iterate from 6 days ago up to today (0 days ago)
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dateStr = day.toIso8601String().split('T')[0];

      final totalSeconds = durationMap[dateStr] ?? 0;
      // Normalize to 0.0 - 1.0 range
      double value = totalSeconds / maxDuration;

      // Ensure a tiny minimum height for visibility if value is 0 but bar exists
      if (value < 0.02) value = 0.02;

      normalized.add(value);
    }

    return normalized;
  }

  List<String> _getLast7DaysLabels() {
    final now = DateTime.now();
    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final List<String> labels = [];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      // weekday is 1 (Mon) to 7 (Sun), array is 0-6
      labels.add(weekdays[day.weekday - 1]);
    }
    return labels;
  }
}

// -----------------------------------------------------------------------------
// CUSTOM BAR CHART WIDGET
// -----------------------------------------------------------------------------
class CustomBarChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final Color color;

  const CustomBarChart({
    super.key,
    required this.data,
    required this.labels,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(data.length, (index) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 12,
              height: 150 * data[index],
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              labels[index],
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        );
      }),
    );
  }
}

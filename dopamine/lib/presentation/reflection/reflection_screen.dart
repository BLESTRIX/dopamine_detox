import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import your existing controllers and repositories
import 'reflection_controller.dart';
import '../../data/repositories/reflection_repository.dart';

// Import services and providers
import '../../data/services/ai_service.dart';
import '../../providers/activity_provider.dart';

// Import the Activity Log Screen
import '../activities/activity_log_screen.dart';

// -----------------------------------------------------------------------------
// RIVERPOD PROVIDER FOR AI SERVICE
// -----------------------------------------------------------------------------
final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});

class ReflectionScreen extends ConsumerStatefulWidget {
  const ReflectionScreen({super.key});

  @override
  ConsumerState<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends ConsumerState<ReflectionScreen> {
  // Controllers & State
  final _journalController = TextEditingController();
  String _selectedMood = 'Calm';
  String _selectedEmoji = '😌';
  double _energyLevel = 3.0;
  bool _isAiLoading = false;

  final List<Map<String, String>> _moods = [
    {'label': 'Happy', 'emoji': '😊'},
    {'label': 'Calm', 'emoji': '😌'},
    {'label': 'Focused', 'emoji': '🧠'},
    {'label': 'Anxious', 'emoji': '😰'},
    {'label': 'Tired', 'emoji': '😴'},
  ];

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // LOGIC: ASK AI
  // ---------------------------------------------------------------------------
  void _askAI() async {
    final text = _journalController.text.trim();
    // Combine Mood + Text so AI has context even if text is empty
    final moodContext = "$_selectedEmoji $_selectedMood";

    setState(() => _isAiLoading = true);

    try {
      final result = await ref
          .read(aiServiceProvider)
          .suggestActivity(moodContext, text);

      if (mounted) {
        setState(() => _isAiLoading = false);

        if (result != null) {
          _showAddDialog(
            title: "AI Suggestion",
            initialActivity: result['activity']!,
            initialCategory: result['category']!,
          );
        } else {
          _showErrorSnackBar('AI could not generate a suggestion.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAiLoading = false);
        _showErrorSnackBar('Error connecting to AI: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // LOGIC: MANUAL ADD
  // ---------------------------------------------------------------------------
  void _manualAdd() {
    _showAddDialog(
      title: "Add Manual Activity",
      initialActivity: "",
      initialCategory: "",
    );
  }

  // ---------------------------------------------------------------------------
  // UI: ADD DIALOG (Shared by AI & Manual)
  // ---------------------------------------------------------------------------
  void _showAddDialog({
    required String title,
    required String initialActivity,
    required String initialCategory,
  }) {
    final activityCtrl = TextEditingController(text: initialActivity);
    final categoryCtrl = TextEditingController(text: initialCategory);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: activityCtrl,
              decoration: const InputDecoration(
                labelText: "Activity Name",
                hintText: "e.g. Read 10 pages",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: categoryCtrl,
              decoration: const InputDecoration(
                labelText: "Category",
                hintText: "e.g. Learning",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (activityCtrl.text.isNotEmpty &&
                  categoryCtrl.text.isNotEmpty) {
                // Save to Activity Provider (Database)
                ref
                    .read(activityLogProvider)
                    .addActivity(activityCtrl.text, categoryCtrl.text);

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Activity added to your Log!")),
                );
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ---------------------------------------------------------------------------
  // UI: BUILD METHOD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reflectionControllerProvider);
    final theme = Theme.of(context);

    // Listen for Save Success
    ref.listen(reflectionControllerProvider, (previous, next) {
      if (next.isSaved) {
        _journalController.clear();
        setState(() {
          _selectedMood = 'Calm';
          _energyLevel = 3.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reflection saved!'),
            backgroundColor: theme.colorScheme.primary,
          ),
        );
        ref.read(reflectionControllerProvider.notifier).reset();
        setState(() {}); // Refresh list
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Daily Check-in')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. MOOD SECTION
            const Text(
              'How are you feeling?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _moods.map((mood) {
                final isSelected = _selectedMood == mood['label'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMood = mood['label']!;
                      _selectedEmoji = mood['emoji']!;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(
                              color: theme.colorScheme.primary,
                              width: 2,
                            )
                          : Border.all(color: Colors.transparent),
                    ),
                    child: Column(
                      children: [
                        Text(
                          mood['emoji']!,
                          style: const TextStyle(fontSize: 32),
                        ),
                        Text(
                          mood['label']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 40),

            // 2. ENERGY SLIDER
            Text(
              'Energy Level: ${_energyLevel.round()}/5',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _energyLevel,
              min: 1,
              max: 5,
              divisions: 4,
              activeColor: theme.colorScheme.primary,
              onChanged: (value) => setState(() => _energyLevel = value),
            ),

            const SizedBox(height: 20),

            // 3. JOURNAL INPUT
            TextField(
              controller: _journalController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'What is on your mind?',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. ACTION BUTTONS (AI & MANUAL)
            Row(
              children: [
                Expanded(
                  child: _isAiLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          onPressed: _askAI,
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text("Suggest Activity"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _manualAdd,
                  icon: const Icon(Icons.add),
                  label: const Text("Manual Add"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // 5. SAVE REFLECTION BUTTON
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () {
                        ref
                            .read(reflectionControllerProvider.notifier)
                            .saveReflection(
                              moodKey: _selectedMood,
                              moodEmoji: _selectedEmoji,
                              text: _journalController.text,
                              energyLevel: _energyLevel,
                            );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: state.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Reflection'),
              ),
            ),

            const SizedBox(height: 20),

            // 6. LINK TO ACTIVITY LOG
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ActivityLogScreen(),
                    ),
                  );
                },
                child: const Text(
                  "View My Activity Log →",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),

            // 7. HISTORY LIST (With Description)
            const Text(
              'Recent Reflections',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            FutureBuilder<List<Map<String, dynamic>>>(
              future: ref
                  .read(reflectionRepositoryProvider)
                  .getReflectionHistory(days: 7),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'No reflections yet. Start today!',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final item = snapshot.data![index];
                    final moodKey = item['mood_key'] ?? '';
                    // Try to find matching emoji, default to neutral
                    String emoji = '😐';
                    try {
                      final mood = _moods.firstWhere(
                        (m) => m['label'] == moodKey,
                        orElse: () => {},
                      );
                      if (mood.isNotEmpty) emoji = mood['emoji']!;
                    } catch (_) {}

                    // ✅ GET DESCRIPTION
                    final description = item['reflection_text'] as String?;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                              title: Text(
                                item['log_date'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '$moodKey • Energy: ${item['energy_level']}/5',
                              ),
                            ),
                            // ✅ DISPLAY DESCRIPTION IF EXISTS
                            if (description != null &&
                                description.isNotEmpty) ...[
                              const Divider(),
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontStyle: FontStyle.italic,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  // TODO: Ensure this is a valid API Key for Gemini API
  final String apiKey = "AIzaSyDtjiWIKih2WJmZFVoGmH53jKxKtd2sUGE";

  Future<Map<String, String>?> suggestActivity(String mood, String text) async {
    // ✅ FIXED: Using gemini-2.5-flash (current free model)
    const String apiUrl =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";

    final String combinedPrompt =
        """
You are a helpful activity suggester. The user is feeling: $mood.
Their reflection is: "$text".

Based on this mood and reflection, suggest ONE concrete activity and a category.

IMPORTANT: Return ONLY a valid JSON object, no markdown, no code blocks, no explanation.
Format: {"activity": "Activity Name", "category": "Category Name"}
    """;

    try {
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": combinedPrompt},
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['candidates'] == null ||
            (data['candidates'] as List).isEmpty) {
          return null;
        }

        String rawText = data['candidates'][0]['content']['parts'][0]['text'];

        // Clean up any markdown formatting
        rawText = rawText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final Map<String, dynamic> result = jsonDecode(rawText);
        return {
          "activity": result['activity'].toString(),
          "category": result['category'].toString(),
        };
      } else {
        print("AI API Error: ${response.body}");
        return null;
      }
    } catch (e) {
      print("AI Network Error: $e");
      return null;
    }
  }
}

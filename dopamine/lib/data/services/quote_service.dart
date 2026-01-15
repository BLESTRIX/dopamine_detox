import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for your HomeController
final quoteServiceProvider = Provider<QuoteService>((ref) {
  return QuoteService();
});

class Quote {
  final String content;
  final String author;

  Quote({required this.content, required this.author});
}

class QuoteService {
  Future<Quote> fetchDailyQuote() async {
    // Try multiple APIs in order until one works

    // Option 1: Try QuoteSlate API (New, reliable, no rate limits)
    try {
      final uri = Uri.parse('https://quoteslate.vercel.app/api/quotes/random');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        return Quote(
          content: data['quote'] ?? "Focus is key.",
          author: data['author'] ?? "Unknown",
        );
      }
    } catch (e) {
      print('QuoteSlate API Error: $e');
    }

    // Option 2: Try ZenQuotes API (Established, 5 requests per 30 seconds)
    try {
      final uri = Uri.parse('https://zenquotes.io/api/random');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        if (data.isNotEmpty) {
          return Quote(
            content: data[0]['q'] ?? "Focus is key.",
            author: data[0]['a'] ?? "Unknown",
          );
        }
      }
    } catch (e) {
      print('ZenQuotes API Error: $e');
    }

    // Option 3: Try Quotable API (180 requests/min)
    try {
      final uri = Uri.parse('https://api.quotable.io/random');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        return Quote(
          content: data['content'] ?? "Focus is key.",
          author: data['author'] ?? "Unknown",
        );
      }
    } catch (e) {
      print('Quotable API Error: $e');
    }

    // Fallback quote if all APIs fail
    return Quote(
      content: "Discipline creates freedom.",
      author: "Jocko Willink",
    );
  }
}

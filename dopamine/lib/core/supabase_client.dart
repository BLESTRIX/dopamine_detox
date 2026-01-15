import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Manual Provider definition
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

class SupabaseConfig {
  static const String url = 'https://iwrkkvrtyrgoeaetjwop.supabase.co';
  static const String anonKey =
      'sb_publishable_MvvmEz7v5viJy2sV6nyLjw_YXsSw01d';

  static Future<void> init() async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }
}

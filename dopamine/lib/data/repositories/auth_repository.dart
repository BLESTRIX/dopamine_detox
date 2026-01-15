import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client.auth);
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final auth = ref.watch(supabaseClientProvider).auth;
  return auth.onAuthStateChange;
});

class AuthRepository {
  final GoTrueClient _auth;

  AuthRepository(this._auth);

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ✅ UPDATED: Added data parameter for metadata (name, avatar)
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      return await _auth.signUp(
        email: email,
        password: password,
        data: data, // Pass metadata to Supabase
      );
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String? get currentUserId => _auth.currentUser?.id;

  String _handleAuthError(dynamic e) {
    if (e is AuthException) {
      return e.message;
    }
    return 'An unexpected error occurred. Please try again.';
  }
}

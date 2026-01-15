import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/supabase_client.dart';

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  const AuthState({this.isLoading = false, this.errorMessage});
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref.watch(authRepositoryProvider), ref);
  },
);

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthController(this._repository, this._ref) : super(const AuthState());

  Future<bool> signIn(String email, String password) async {
    state = const AuthState(isLoading: true);
    try {
      await _repository.signIn(email: email, password: password);
      state = const AuthState(isLoading: false);
      return true;
    } catch (e) {
      state = AuthState(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  // ✅ UPDATED: Accepts name and avatar
  Future<bool> signUp(
    String email,
    String password,
    String name,
    String avatar,
  ) async {
    state = const AuthState(isLoading: true);
    try {
      // 1. Sign up with metadata
      final response = await _repository.signUp(
        email: email,
        password: password,
        data: {'display_name': name, 'avatar': avatar},
      );

      // 2. Explicitly update the profile table to ensure data is synced
      // (In case the trigger only creates the row but doesn't copy metadata)
      if (response.user != null) {
        final client = _ref.read(supabaseClientProvider);
        await client
            .from('profiles')
            .update({'display_name': name, 'avatar': avatar})
            .eq('user_id', response.user!.id);
      }

      state = const AuthState(isLoading: false);
      return true;
    } catch (e) {
      state = AuthState(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateDisplayName(String displayName) async {
    state = const AuthState(isLoading: true);
    try {
      final client = _ref.read(supabaseClientProvider);
      final userId = _repository.currentUserId;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await client
          .from('profiles')
          .update({'display_name': displayName})
          .eq('user_id', userId);

      state = const AuthState(isLoading: false);
      return true;
    } catch (e) {
      state = AuthState(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _repository.signOut();
    } catch (e) {
      print('Sign out error: $e');
    }
  }
}

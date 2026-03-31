import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? getCurrentUser() => _client.auth.currentUser;

  bool get isAuthenticated => getCurrentUser() != null;

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'http://localhost:63626/',
    );
  }

  Future<void> signInWithApple() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'http://localhost:63626/',
    );
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUpWithEmail(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  String get currentUserName {
    final user = getCurrentUser();
    return user?.userMetadata?['full_name'] as String? ??
        user?.email?.split('@').first ??
        'Usuário';
  }

  String get currentUserEmail => getCurrentUser()?.email ?? '';

  String? get currentUserAvatar =>
      getCurrentUser()?.userMetadata?['avatar_url'] as String?;

  bool get isPremium {
    final meta = getCurrentUser()?.userMetadata;
    return meta?['is_premium'] as bool? ?? false;
  }
}

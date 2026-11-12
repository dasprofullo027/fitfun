import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> register(
    String email,
    String password,
    String fullName, {
    String? goal,
  }) async {
    final res = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim()},
    );

    if (res.user != null) {
      try {
        await _client.from('profiles').upsert({
          'id': res.user!.id,
          'full_name': fullName.trim(),
          'email': email.trim(),
          'goal': goal ?? 'Build Muscle',
          'streak': 0,
        });
      } catch (e) {
        // Fallback or ignore if trigger created it
      }
    }
    return res;
  }

  Future<AuthResponse> login(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  Future<UserModel?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final res = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (res != null) {
        return UserModel.fromJson(Map<String, dynamic>.from(res));
      } else {
        // If profile record doesn't exist yet, create a default one
        final defaultProfile = {
          'id': user.id,
          'full_name': user.userMetadata?['full_name'] ?? 'FitForge Athlete',
          'email': user.email ?? '',
          'goal': 'Build Muscle',
          'streak': 0,
        };
        await _client.from('profiles').upsert(defaultProfile);
        return UserModel.fromJson(defaultProfile);
      }
    } catch (e) {
      return null;
    }
  }

  Future<UserModel?> updateProfile({
    required String fullName,
    String? goal,
    String? avatarUrl,
  }) async {
    final user = currentUser;
    if (user == null) return null;

    final updateData = <String, dynamic>{
      'full_name': fullName.trim(),
      if (goal != null) 'goal': goal,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };

    final res = await _client
        .from('profiles')
        .update(updateData)
        .eq('id', user.id)
        .select()
        .single();

    return UserModel.fromJson(Map<String, dynamic>.from(res));
  }

  Future<void> updateStreak(int streak) async {
    final user = currentUser;
    if (user == null) return;

    await _client
        .from('profiles')
        .update({'streak': streak})
        .eq('id', user.id);
  }
}

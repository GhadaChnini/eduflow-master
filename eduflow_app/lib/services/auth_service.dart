import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(supabaseProvider).auth.onAuthStateChange.map((event) {
    return event.session?.user;
  });
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(supabaseProvider).auth.currentUser;
});

class AuthService {
  final SupabaseClient _supabase;

  AuthService(this._supabase);

Future<AuthResponse> signUp({
  required String email,
  required String password,
  required String name,
  required String role,
  int? gradeLevel,
}) async {
  final response = await _supabase.auth.signUp(
    email: email,
    password: password,
    data: {
      'name': name,
      'role': role,
      'grade_level': gradeLevel,
    },
  );

  if (response.user != null) {
    await _supabase.from('profiles').insert({
      'id': response.user!.id,
      'email': email,
      'name': name,
      'role': role,
      'grade_level': gradeLevel,
      'points': 0,
    });
  }

  return response;
}

  // Sign in
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

Future<Map<String, dynamic>?> getCurrentProfile() async {
  final user = _supabase.auth.currentUser;
  if (user == null) return null;

  final response = await _supabase
      .from('profiles')
      .select()
      .eq('id', user.id)
      .maybeSingle();

  return response;
}

  // Update profile
  Future<void> updateProfile(Map<String, dynamic> data) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('profiles').update(data).eq('id', user.id);
  }

  // Apply as teacher
  Future<void> applyAsTeacher({
    required String name,
    required String email,
    required String bio,
  }) async {
    await _supabase.from('teacher_applications').insert({
      'name': name,
      'email': email,
      'bio': bio,
      'status': 'pending',
    });
  }

  // Check if user is teacher
  Future<bool> isTeacher() async {
    final profile = await getCurrentProfile();
    return profile?['role'] == 'teacher' || profile?['role'] == 'admin';
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseProvider));
});

// Current user profile provider
final profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final supabase = ref.watch(supabaseProvider);
  final response = await supabase
      .from('profiles')
      .select()
      .eq('id', user.id)
      .single();

  return response;
});
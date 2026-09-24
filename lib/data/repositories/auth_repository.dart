import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Repository handling all authentication operations via Supabase Auth.
class AuthRepository {
  final _supabase = Supabase.instance.client;

  // ── Sign Up ────────────────────────────────────────────────────────────────

  /// Creates a new account with [email], [password], and [fullName].
  /// Sends a verification email using the provided redirect URL.
  Future<AuthResponse> signUpWithEmail(
    String email,
    String password,
    String fullName,
  ) async {
    return await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim()},
      emailRedirectTo: 'io.supabase.nxnapp://login-callback/',
    );
  }

  // ── Sign In ────────────────────────────────────────────────────────────────

  /// Signs in with [email] and [password].
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────

  /// Signs out the current user and clears locally stored user data.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    // Intentionally keep 'terms_accepted' so terms are only shown once per device
    await prefs.remove('user_role');
  }

  // ── Session Helpers ────────────────────────────────────────────────────────

  /// Returns the currently authenticated Supabase [User], or null.
  User? getCurrentUser() => _supabase.auth.currentUser;

  /// Returns the current active [Session], or null.
  Session? getCurrentSession() => _supabase.auth.currentSession;

  /// Whether a user is currently signed in with a valid session.
  bool get isLoggedIn => _supabase.auth.currentSession != null;

  // ── Password Reset ─────────────────────────────────────────────────────────

  /// Sends a password reset email to [email].
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: 'io.supabase.nxnapp://reset-callback/',
    );
  }

  // ── Terms of Service ──────────────────────────────────────────────────────

  /// Persists the user's acceptance of the Terms & Conditions.
  Future<void> acceptTerms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('terms_accepted', true);
  }

  /// Returns true if the user has previously accepted the Terms & Conditions.
  Future<bool> hasAcceptedTerms() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('terms_accepted') ?? false;
  }
}

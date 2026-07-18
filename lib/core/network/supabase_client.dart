import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientWrapper {
  static SupabaseClientWrapper? _instance;
  
  SupabaseClientWrapper._();

  static SupabaseClientWrapper get instance {
    _instance ??= SupabaseClientWrapper._();
    return _instance!;
  }

  SupabaseClient get client => Supabase.instance.client;

  /// Returns the current active user session.
  Session? get currentSession => client.auth.currentSession;

  /// Returns the authorization header token.
  String get authHeader => currentSession?.accessToken ?? '';
}

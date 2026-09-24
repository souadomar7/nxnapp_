import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for in-app notifications and device token management.
class NotificationRepository {
  final _supabase = Supabase.instance.client;

  String get _uid => _supabase.auth.currentUser!.id;

  // ── Fetch Notifications ────────────────────────────────────────────────────

  /// Returns the most recent [limit] notifications for the current user.
  Future<List<Map<String, dynamic>>> getNotifications({int limit = 50}) async {
    final data = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', _uid)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(data as List);
  }

  // ── Mark as Read ──────────────────────────────────────────────────────────

  /// Marks a single notification [notificationId] as read.
  Future<void> markAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId)
        .eq('user_id', _uid);
  }

  /// Marks all notifications for the current user as read.
  Future<void> markAllAsRead() async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', _uid)
        .eq('is_read', false);
  }

  // ── Unread Count ──────────────────────────────────────────────────────────

  /// Returns the number of unread notifications.
  Future<int> getUnreadCount() async {
    final data = await _supabase
        .from('notifications')
        .select('id')
        .eq('user_id', _uid)
        .eq('is_read', false);

    return (data as List).length;
  }

  // ── Device Token ──────────────────────────────────────────────────────────

  /// Upserts the FCM/APNs device [token] for the current user.
  ///
  /// [platform] should be `'ios'`, `'android'`, or `'web'`.
  Future<void> saveDeviceToken(String token, String platform) async {
    await _supabase.from('device_tokens').upsert(
      {
        'user_id': _uid,
        'token': token,
        'platform': platform,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'token',
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../../core/errors/app_exception.dart';

class PaymentRepository {
  final SupabaseClient _supabase;

  PaymentRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  String get _currentUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) throw const AuthException(message: 'User must be authenticated');
    return user.id;
  }

  /// Get payment history for current user
  Future<List<Map<String, dynamic>>> getMyPayments() async {
    try {
      final res = await _supabase
          .from('payments')
          .select('*')
          .eq('payer_id', _currentUserId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error loading payments: $e');
      return [];
    }
  }

  /// Get invoices for current user
  Future<List<Map<String, dynamic>>> getMyInvoices() async {
    try {
      final res = await _supabase
          .from('sme_invoices')
          .select('*')
          .eq('seller_id', _currentUserId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error loading invoices: $e');
      return [];
    }
  }
}

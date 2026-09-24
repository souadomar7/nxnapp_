import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for reading wallet balances and transaction history.
///
/// Balance mutations are server-side only — this client only reads.
class WalletRepository {
  final _supabase = Supabase.instance.client;

  String get _uid => _supabase.auth.currentUser!.id;

  // ── Internal wallet ID cache ───────────────────────────────────────────────
  String? _cachedWalletId;

  // ── Wallet ─────────────────────────────────────────────────────────────────

  /// Returns the wallet row for the current user.
  /// Creates one if it does not exist.
  Future<Map<String, dynamic>> getWallet() async {
    final data = await _supabase
        .from('wallets')
        .select()
        .eq('user_id', _uid)
        .maybeSingle();

    if (data == null) {
      return await _initWallet();
    }

    _cachedWalletId = data['id'] as String?;
    return Map<String, dynamic>.from(data);
  }

  /// Inserts a zero-balance wallet for the current user.
  Future<Map<String, dynamic>> _initWallet() async {
    final data = await _supabase
        .from('wallets')
        .insert({
          'user_id': _uid,
          'currency': 'AED',
          'balance_aed': 0.0,
        })
        .select()
        .single();

    _cachedWalletId = data['id'] as String?;
    return Map<String, dynamic>.from(data);
  }

  // ── Transactions ───────────────────────────────────────────────────────────

  /// Returns the most recent [limit] wallet transactions for the current user.
  Future<List<Map<String, dynamic>>> getTransactions({int limit = 50}) async {
    // Ensure wallet exists and ID is cached.
    if (_cachedWalletId == null) await getWallet();

    final data = await _supabase
        .from('wallet_transactions')
        .select()
        .eq('wallet_id', _cachedWalletId!)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(data as List);
  }

  // ── Balance ────────────────────────────────────────────────────────────────

  /// Fetches and returns the current wallet balance in AED.
  Future<double> getBalance() async {
    final wallet = await getWallet();
    return (wallet['balance_aed'] as num?)?.toDouble() ?? 0.0;
  }
}

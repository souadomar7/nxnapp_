import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for KYC submission, document upload, and status queries.
class KYCRepository {
  final _supabase = Supabase.instance.client;

  String get _uid => _supabase.auth.currentUser!.id;

  // ── Submit KYC ─────────────────────────────────────────────────────────────

  /// Creates a new KYC submission record with status `pending`.
  ///
  /// Returns the new submission's UUID.
  Future<String> submitKyc({
    required String trn,
    String? emiratesIdUrl,
    String? tradeLicenseUrl,
  }) async {
    final data = await _supabase
        .from('kyc_submissions')
        .insert({
          'user_id': _uid,
          'trn': trn.trim(),
          if (emiratesIdUrl != null) 'emirates_id_url': emiratesIdUrl,
          if (tradeLicenseUrl != null) 'trade_license_url': tradeLicenseUrl,
          'status': 'pending',
          'submitted_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select('id')
        .single();

    return data['id'] as String;
  }

  // ── KYC Status ────────────────────────────────────────────────────────────

  /// Returns the status string of the most recent KYC submission.
  /// Returns null if no submission exists.
  Future<String?> getMyKycStatus() async {
    final data = await _supabase
        .from('kyc_submissions')
        .select('status')
        .eq('user_id', _uid)
        .order('submitted_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return data?['status'] as String?;
  }

  // ── Document Upload ───────────────────────────────────────────────────────

  /// Uploads [file] to the `kyc-documents` storage bucket.
  ///
  /// [docType] should be one of: `emirates_id`, `trade_license`, `other`.
  ///
  /// Returns the storage object path.
  Future<String> uploadDocument(File file, String docType) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$_uid/${docType}_$timestamp.jpg';

    await _supabase.storage.from('kyc-documents').upload(
          storagePath,
          file,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );

    return storagePath;
  }

  // ── Signed URL ────────────────────────────────────────────────────────────

  /// Generates a signed URL for [storagePath] valid for 15 minutes (900 s).
  Future<String> getSignedUrl(String storagePath) async {
    final response = await _supabase.storage
        .from('kyc-documents')
        .createSignedUrl(storagePath, 900);
    return response;
  }
}

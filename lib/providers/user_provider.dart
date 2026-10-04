import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProvider extends ChangeNotifier {
  String? _businessName;
  String? _contactNumber;
  String? _licenseNumber;
  String? _email;
  bool _isDocumentUploaded = true; // Default true so document is uploaded once
  String? _documentFileName;
  bool _termsAccepted = false; // Tracks whether T&C have been accepted on this device

  UserProvider() {
    _loadUser();
  }

  bool get isLoggedIn => true;
  bool get isDocumentUploaded => _isDocumentUploaded;
  String? get documentFileName => _documentFileName ?? 'Trade_License_CN2891048.pdf';
  String get displayName => _businessName ?? 'Souad Omar Store';
  String get email => _email ?? 'souadomar774@gmail.com';
  String get licenseNumber => _licenseNumber ?? 'CN-2891048';
  String get contactNumber => _contactNumber ?? '+971501234567';
  bool get termsAccepted => _termsAccepted;

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _businessName = prefs.getString('user_business_name');
      _contactNumber = prefs.getString('user_contact_number');
      _licenseNumber = prefs.getString('user_license_number');
      _email = prefs.getString('user_email');
      _isDocumentUploaded = prefs.getBool('user_doc_uploaded') ?? true;
      _documentFileName = prefs.getString('user_doc_filename');
      _termsAccepted = prefs.getBool('terms_accepted') ?? false;
      notifyListeners();
    } catch (_) {}
  }

  /// Call this when the user accepts the Terms & Conditions.
  /// Persists locally and synchronizes a digital audit record to Supabase.
  Future<void> acceptTerms() async {
    _termsAccepted = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('terms_accepted', true);
      await prefs.setString('terms_accepted_at', DateTime.now().toIso8601String());
    } catch (_) {}

    // Persist server-side consent audit record if user is authenticated
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('profiles').update({
          'terms_accepted_at': DateTime.now().toIso8601String(),
          'terms_version': '1.0.2',
        }).eq('id', user.id);
      }
    } catch (e) {
      debugPrint('Terms server audit update note: $e');
    }

    notifyListeners();
  }

  Future<void> setDocumentUploaded(String fileName) async {
    _isDocumentUploaded = true;
    _documentFileName = fileName;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_doc_uploaded', true);
      await prefs.setString('user_doc_filename', fileName);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setUser({
    required String businessName,
    required String contactNumber,
    required String licenseNumber,
    String? email,
  }) async {
    _businessName = businessName;
    _contactNumber = contactNumber;
    _licenseNumber = licenseNumber;
    _email = email;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_business_name', businessName);
      await prefs.setString('user_contact_number', contactNumber);
      await prefs.setString('user_license_number', licenseNumber);
      if (email != null) await prefs.setString('user_email', email);
    } catch (_) {}

    notifyListeners();
  }

  Future<void> clearUser() async {
    _businessName = null;
    _contactNumber = null;
    _licenseNumber = null;
    _email = null;
    _isDocumentUploaded = false;
    _documentFileName = null;
    // Note: we intentionally keep _termsAccepted = true on logout
    // so the user doesn't need to re-accept T&C after re-login on same device.

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_business_name');
      await prefs.remove('user_contact_number');
      await prefs.remove('user_license_number');
      await prefs.remove('user_email');
      await prefs.remove('user_doc_uploaded');
      await prefs.remove('user_doc_filename');
    } catch (_) {}

    notifyListeners();
  }
}

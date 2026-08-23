import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  String? _businessName;
  String? _contactNumber;
  String? _licenseNumber;
  String? _email;
  bool _isDocumentUploaded = true; // Default true so document is uploaded once
  String? _documentFileName;

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

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _businessName = prefs.getString('user_business_name');
      _contactNumber = prefs.getString('user_contact_number');
      _licenseNumber = prefs.getString('user_license_number');
      _email = prefs.getString('user_email');
      _isDocumentUploaded = prefs.getBool('user_doc_uploaded') ?? true;
      _documentFileName = prefs.getString('user_doc_filename');
      notifyListeners();
    } catch (_) {}
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

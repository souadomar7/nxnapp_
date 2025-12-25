import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  // Default to Demo Data for "Fix the data" request
  String? _businessName = 'Al Falak Logistics';
  String? _contactNumber = '+971 50 123 4567';
  String? _licenseNumber = 'CN-1234567';
  String? _email = 'suad.sayed@example.com';

  bool get isLoggedIn => _businessName != null;
  String get displayName => _businessName ?? 'Guest';
  String get email => _email ?? '';
  String get licenseNumber => _licenseNumber ?? '';
  String get contactNumber => _contactNumber ?? '';

  void setUser({
    required String businessName,
    required String contactNumber,
    required String licenseNumber,
    String? email,
  }) {
    _businessName = businessName;
    _contactNumber = contactNumber;
    _licenseNumber = licenseNumber;
    _email = email;
    notifyListeners();
  }
  
  void clearUser() {
    _businessName = null;
    _contactNumber = null;
    _licenseNumber = null;
    _email = null;
    notifyListeners();
  }
}

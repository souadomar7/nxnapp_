import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  // Default to Demo Data for "Fix the data" request
  // Default to null so guests are identified correctly
  String? _businessName;
  String? _contactNumber;
  String? _licenseNumber;
  String? _email;

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

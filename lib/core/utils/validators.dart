/// Collection of static form field validators for the NXN app.
class Validators {
  Validators._();

  /// Returns 'Required' if [v] is null or empty.
  static String? required(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    return null;
  }

  /// Returns 'Invalid email' if [v] is not a valid email address.
  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final regex = RegExp(
      r'^[a-zA-Z0-9.!#$%&'
      r"'*+/=?^_`{|}~-]+"
      r'@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?'
      r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$',
    );
    if (!regex.hasMatch(v.trim())) return 'Invalid email';
    return null;
  }

  /// Returns 'Invalid phone' if [v] is not a valid phone number.
  /// Accepts optional leading + and 7–15 digits.
  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final cleaned = v.replaceAll(RegExp(r'[\s\-()]'), '');
    final regex = RegExp(r'^\+?[0-9]{7,15}$');
    if (!regex.hasMatch(cleaned)) return 'Invalid phone';
    return null;
  }

  /// Returns 'Min 6 characters' if [v] is shorter than 6 characters.
  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    if (v.length < 6) return 'Min 6 characters';
    return null;
  }

  /// Returns 'Passwords do not match' if [v] differs from [original].
  static String? confirmPassword(String? v, String original) {
    if (v == null || v.isEmpty) return 'Required';
    if (v != original) return 'Passwords do not match';
    return null;
  }

  /// Returns 'TRN must be 15 digits' if [v] is not a 15-digit Tax Registration Number.
  static String? trn(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final cleaned = v.replaceAll(RegExp(r'\s'), '');
    if (!RegExp(r'^\d{15}$').hasMatch(cleaned)) return 'TRN must be 15 digits';
    return null;
  }

  /// Returns 'Invalid UAE IBAN' if [v] is not a valid UAE IBAN.
  /// UAE IBANs start with 'AE' followed by 21 digits (total 23 chars).
  static String? iban(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final cleaned = v.replaceAll(RegExp(r'\s'), '').toUpperCase();
    if (!RegExp(r'^AE\d{21}$').hasMatch(cleaned)) return 'Invalid UAE IBAN';
    return null;
  }
}

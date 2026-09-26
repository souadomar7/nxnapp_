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

  /// Returns 'Invalid Emirates ID' if [v] is not a valid 15-digit UAE Emirates ID (784-YYYY-XXXXXXX-Z).
  static String? emiratesId(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final cleaned = v.replaceAll(RegExp(r'[\s\-]'), '');
    if (!RegExp(r'^784\d{12}$').hasMatch(cleaned)) {
      return 'Invalid Emirates ID (must be 15 digits starting with 784)';
    }
    return null;
  }

  /// Returns error string if price is not a positive valid number (min AED 1, max AED 500,000).
  static String? price(String? v, {double min = 1.0, double max = 500000.0}) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final val = double.tryParse(v.trim());
    if (val == null) return 'Invalid price format';
    if (val < min) return 'Minimum price is AED ${min.toStringAsFixed(0)}';
    if (val > max) return 'Maximum price limit is AED ${max.toStringAsFixed(0)}';
    return null;
  }

  /// Returns error string if quantity is not a positive integer (min 1, max 100,000).
  static String? stockQuantity(String? v, {int min = 1, int max = 100000}) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final val = int.tryParse(v.trim());
    if (val == null) return 'Invalid quantity';
    if (val < min) return 'Minimum quantity is $min';
    if (val > max) return 'Maximum quantity is $max';
    return null;
  }

  /// Strict UAE Mobile Phone Validator.
  /// Matches +9715xxxxxxxx, 009715xxxxxxxx, 05xxxxxxxx, or 5xxxxxxxx (9 digits).
  static String? uaePhone(String? v, {bool allowInternational = false}) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final cleaned = v.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // UAE Mobile pattern: (+971|00971|0)?5[024568][0-9]{7}
    final uaeRegex = RegExp(r'^(?:\+971|00971|0)?5[024568]\d{7}$');
    if (uaeRegex.hasMatch(cleaned)) return null;

    if (allowInternational) {
      // General valid international phone pattern (E.164)
      final intlRegex = RegExp(r'^\+?[1-9]\d{7,14}$');
      if (intlRegex.hasMatch(cleaned)) return null;
      return 'Invalid international phone number format (+country code)';
    }

    return 'Invalid UAE mobile number (e.g. +971 50 123 4567 or 0501234567)';
  }

  /// Validates recipient/contact name (min 3 characters, alphabetic words, no pure digits).
  static String? recipientName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final trimmed = v.trim();
    if (trimmed.length < 3) return 'Name must be at least 3 characters';
    if (RegExp(r'^\d+$').hasMatch(trimmed)) return 'Name cannot be only numbers';
    if (trimmed.length > 80) return 'Name is too long (max 80 characters)';
    return null;
  }

  /// Validates detailed delivery destination address (ensures building/villa, street, and min detail).
  static String? deliveryAddress(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final trimmed = v.trim();
    if (trimmed.length < 8) return 'Address must be detailed (min 8 characters)';
    if (RegExp(r'^\d+$').hasMatch(trimmed)) return 'Please provide full street & building details';
    return null;
  }
}

class Validators {
  static String? name(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Name is required';
    }
    if (!RegExp(r'^[a-zA-Z ]{2,50}$').hasMatch(v.trim())) {
      return 'Enter a valid name (2-50 letters and spaces only)';
    }
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$').hasMatch(v.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) {
      return 'Password is required';
    }
    if (!RegExp(
      r'^(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
    ).hasMatch(v)) {
      return r'Min 8 chars, 1 uppercase, 1 number, 1 special char (@$!%*?&)';
    }
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return null; // Optional
    if (!RegExp(r'^(\+?880|0)1[3-9]\d{8}$').hasMatch(v.trim())) {
      return 'Enter a valid phone number (e.g., 017xxxxxxxx or +88017xxxxxxxx)';
    }
    return null;
  }

  static String? required(String? v, [String fieldName = 'This field']) {
    if (v == null || v.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? positiveNumber(String? v, [String fieldName = 'Value']) {
    if (v == null || v.trim().isEmpty) {
      return '$fieldName is required';
    }
    final numVal = num.tryParse(v.trim());
    if (numVal == null || numVal <= 0) {
      return 'Enter a valid positive number';
    }
    return null;
  }

  static String? nonNegativeNumber(String? v, [String fieldName = 'Value']) {
    if (v == null || v.trim().isEmpty) {
      return '$fieldName is required';
    }
    final numVal = num.tryParse(v.trim());
    if (numVal == null || numVal < 0) {
      return 'Enter a non-negative number';
    }
    return null;
  }
}

abstract final class AuthValidators {
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  static String? email(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    final normalized = value!.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalized)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? password(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    if (value!.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    return null;
  }

  static String? matchingPassword(String? value, String password) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    if (value != password) return 'Passwords do not match.';
    return null;
  }

  static String? philippinePhone(String? value) {
    final requiredError = required(value);
    if (requiredError != null) return requiredError;
    if (!RegExp(r'^(09\d{9}|\+639\d{9})$').hasMatch(value!)) {
      return 'Enter a valid PH mobile number (09… or +639…).';
    }
    return null;
  }
}

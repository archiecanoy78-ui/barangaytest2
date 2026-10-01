class Validators {
  static String? validateFirstName(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'First name is required.';
    if (v.length < 3) return 'First name must be at least 3 characters.';
    if (v.length > 50) return 'First name cannot exceed 50 characters.';
    final nameReg = RegExp(r"^[A-Za-zÀ-ž\s]+$");
    if (!nameReg.hasMatch(v)) return 'First name can only contain letters and spaces.';
    return null;
  }

  static String? validateLastName(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Last name is required.';
    if (v.length < 3) return 'Last name must be at least 3 characters.';
    if (v.length > 50) return 'Last name cannot exceed 50 characters.';
    final nameReg = RegExp(r"^[A-Za-zÀ-ž\s]+$");
    if (!nameReg.hasMatch(v)) return 'Last name can only contain letters and spaces.';
    return null;
  }

  static String? validateFullName(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Full name is required.';
    if (v.length < 3) return 'Full name must be at least 3 characters.';
    if (v.length > 100) return 'Full name must not exceed 100 characters.';
    final nameReg = RegExp(r"^[A-Za-zÀ-ž\s]+$");
    if (!nameReg.hasMatch(v)) return 'Full name can only contain letters and spaces.';
    return null;
  }

  static String? validateName(String value) => validateFullName(value);

  static String? validateUsernameMobile(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Mobile number username is required.';
    final mobileReg = RegExp(r'^09\d{9}$');
    if (!mobileReg.hasMatch(v)) return 'Enter a valid 11-digit number starting with 09.';
    return null;
  }

  static String? validateUsername(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Username is required.';
    if (RegExp(r'^\d+$').hasMatch(v)) {
      return validateUsernameMobile(v);
    }
    if (v.length < 3) return 'Username must be at least 3 characters.';
    if (v.length > 50) return 'Username cannot exceed 50 characters.';
    final userReg = RegExp(r'^[A-Za-z0-9_\.]+$');
    if (!userReg.hasMatch(v)) return 'Username can only contain letters, numbers, underscores, and periods.';
    return null;
  }

  static String? validatePhone(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Phone number is required.';
    final phoneReg = RegExp(r'^09\d{9}$');
    if (!phoneReg.hasMatch(v)) return 'Enter a valid 11-digit number starting with 09.';
    return null;
  }

  static String? validateMessage(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Message cannot be empty.';
    if (v.length > 200) return 'Message must not exceed 200 characters.';
    return null;
  }

  static String? validateOptionalContact(String value) {
    final v = value.trim();
    if (v.isEmpty) return null;
    if (v.contains('@')) return validateEmail(v);
    if (RegExp(r'^\d+$').hasMatch(v)) return validatePhone(v);
    return 'Contact must be a valid email or 11-digit phone number.';
  }

  static String? validateEmail(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Email is required.';
    final emailReg = RegExp(r"^[\w\.-]+@[\w\.-]+\.[A-Za-z]{2,}$");
    if (!emailReg.hasMatch(v)) return 'Enter a valid email address.';
    return null;
  }

  static String? validatePassword(String value) {
    final v = value;
    if (v.isEmpty) return 'Password is required.';
    final passReg = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$');
    if (!passReg.hasMatch(v)) {
      return 'Password must be 8+ chars with uppercase, lowercase, digit, and special char.';
    }
    return null;
  }
}

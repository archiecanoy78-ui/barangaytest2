class UtilsValidators {
  static String? validatePhone(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Phone number is required.';
    final phoneReg = RegExp(r'^\d{11}$');
    if (!phoneReg.hasMatch(v)) return 'Phone must be exactly 11 digits (e.g. 09123456789).';
    return null;
  }

  static String? validateOptionalContact(String value) {
    final v = value.trim();
    if (v.isEmpty) return null;
    if (v.contains('@')) return validateEmail(v);
    final digitsOnly = RegExp(r'^\d+$');
    if (digitsOnly.hasMatch(v)) return validatePhone(v);
    return 'Contact must be a valid email or 11-digit phone number.';
  }

  static String? validateName(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Name is required.';
    final nameReg = RegExp(r"^[A-Za-zÀ-ž\s'\-]+$");
    if (!nameReg.hasMatch(v)) return 'Name may contain letters, spaces, hyphens, or apostrophes only.';
    if (v.length < 2) return 'Name is too short.';
    if (v.length > 60) return 'Name is too long.';
    return null;
  }

  static String? validateUsername(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Username is required.';
    final userReg = RegExp(r'^[A-Za-z0-9_\.\-]{3,32}$');
    if (!userReg.hasMatch(v)) return 'Username must be 3-32 chars; letters, numbers, dot, underscore or dash.';
    return null;
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
    if (v.length < 8 || v.length > 12) return 'Password must be 8-12 characters.';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Include at least one uppercase letter.';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Include at least one lowercase letter.';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Include at least one digit.';
    if (!RegExp(r'[!@#\$%\^&\*(),.?":\{\}\|<>_\-+=\[\]\\/]').hasMatch(v)) return 'Include at least one special character.';
    return null;
  }
}

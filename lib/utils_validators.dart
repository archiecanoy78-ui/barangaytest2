import 'validators.dart';

class UtilsValidators {
  static String? validateFirstName(String value) => Validators.validateFirstName(value);
  static String? validateLastName(String value) => Validators.validateLastName(value);
  static String? validateName(String value) => Validators.validateName(value);
  static String? validateUsername(String value) => Validators.validateUsername(value);
  static String? validatePhone(String value) => Validators.validatePhone(value);
  static String? validateOptionalContact(String value) => Validators.validateOptionalContact(value);
  static String? validateEmail(String value) => Validators.validateEmail(value);
  static String? validatePassword(String value) => Validators.validatePassword(value);
}

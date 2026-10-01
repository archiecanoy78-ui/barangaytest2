import 'package:flutter_test/flutter_test.dart';
import 'package:barangaytest/validators.dart';

void main() {
  group('Validators Unit Tests', () {
    test('First Name validation', () {
      expect(Validators.validateFirstName(''), 'First name is required.');
      expect(Validators.validateFirstName('  '), 'First name is required.');
      expect(Validators.validateFirstName('Jo'), 'First name must be at least 3 characters.');
      expect(Validators.validateFirstName('a' * 51), 'First name cannot exceed 50 characters.');
      expect(Validators.validateFirstName('John123'), 'First name can only contain letters and spaces.');
      expect(Validators.validateFirstName('John'), null);
      expect(Validators.validateFirstName('  Maria Santos  '), null);
    });

    test('Last Name validation', () {
      expect(Validators.validateLastName(''), 'Last name is required.');
      expect(Validators.validateLastName('Do'), 'Last name must be at least 3 characters.');
      expect(Validators.validateLastName('b' * 51), 'Last name cannot exceed 50 characters.');
      expect(Validators.validateLastName('Doe@#'), 'Last name can only contain letters and spaces.');
      expect(Validators.validateLastName('Dela Cruz'), null);
    });

    test('Full Name validation', () {
      expect(Validators.validateFullName(''), 'Full name is required.');
      expect(Validators.validateFullName('a' * 101), 'Full name must not exceed 100 characters.');
      expect(Validators.validateFullName('Juan Dela Cruz'), null);
    });

    test('Username validation', () {
      expect(Validators.validateUsername(''), 'Username is required.');
      expect(Validators.validateUsername('ab'), 'Username must be at least 3 characters.');
      expect(Validators.validateUsername('a' * 51), 'Username cannot exceed 50 characters.');
      expect(Validators.validateUsername('user!name'), 'Username can only contain letters, numbers, underscores, and periods.');
      expect(Validators.validateUsername('john_doe.99'), null);
      expect(Validators.validateUsername('a' * 50), null);
    });

    test('Phone Number validation', () {
      expect(Validators.validatePhone(''), 'Phone number is required.');
      expect(Validators.validatePhone('08123456789'), 'Enter a valid 11-digit number starting with 09.');
      expect(Validators.validatePhone('0912345678'), 'Enter a valid 11-digit number starting with 09.');
      expect(Validators.validatePhone('091234567890'), 'Enter a valid 11-digit number starting with 09.');
      expect(Validators.validatePhone('0912345678a'), 'Enter a valid 11-digit number starting with 09.');
      expect(Validators.validatePhone('09170000001'), null);
    });

    test('Message Box validation', () {
      expect(Validators.validateMessage(''), 'Message cannot be empty.');
      expect(Validators.validateMessage('a' * 201), 'Message must not exceed 200 characters.');
      expect(Validators.validateMessage('Hello Barangay Staff'), null);
    });
  });
}

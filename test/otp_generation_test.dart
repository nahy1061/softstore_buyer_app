import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:softstore_buyer_app/core/errors/failures.dart';
import 'package:softstore_buyer_app/features/cart/repository/cart_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Email OTP Checkout Verification Tests', () {
    final repo = CartRepository.instance;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('sendVerificationOtp throws AuthFailure if email is empty', () async {
      await expectLater(
        repo.sendVerificationOtp(''),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('verifyCheckoutOtp throws AuthFailure if code is empty', () async {
      await expectLater(
        repo.verifyCheckoutOtp(''),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('isEmailVerified and markEmailVerified persist verification so email is verified only one time', () async {
      const testEmail = 'permanent_buyer@domain.pk';

      // Initially unverified
      expect(await repo.isEmailVerified(testEmail), isFalse);

      // Mark verified once
      await repo.markEmailVerified(testEmail);

      // Now verified permanently
      expect(await repo.isEmailVerified(testEmail), isTrue);
      expect(await repo.isEmailVerified('  PERMANENT_BUYER@DOMAIN.PK  '), isTrue,
          reason: 'Case-insensitive email check must pass');
    });
  });
}

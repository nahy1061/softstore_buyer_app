import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:softstore_buyer_app/features/profile/screens/privacy_policy_screen.dart';
import 'package:softstore_buyer_app/features/profile/screens/terms_and_conditions_screen.dart';

void main() {
  testWidgets('PrivacyPolicyScreen renders all sections correctly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PrivacyPolicyScreen(),
      ),
    );

    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('SoftStore Privacy Policy'), findsOneWidget);
    expect(find.text('Data Ownership & Tenant Isolation'), findsOneWidget);
    expect(find.text('Information We Collect'), findsOneWidget);

    final useDataFinder = find.text('How We Use Your Data');
    await tester.scrollUntilVisible(useDataFinder, 200);
    expect(useDataFinder, findsOneWidget);

    final emailFinder = find.text('sales@softstore.pk');
    await tester.scrollUntilVisible(emailFinder, 200);
    expect(emailFinder, findsOneWidget);
  });

  testWidgets('TermsAndConditionsScreen renders all sections correctly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TermsAndConditionsScreen(),
      ),
    );

    expect(find.text('Terms & Conditions'), findsOneWidget);
    expect(find.text('Platform Agreement'), findsOneWidget);
    expect(find.text('Acceptance of These Terms'), findsOneWidget);
    expect(find.text('Scope of Service'), findsOneWidget);

    final regFinder = find.text('Account Registration & Security');
    await tester.scrollUntilVisible(regFinder, 200);
    expect(regFinder, findsOneWidget);

    final emailFinder = find.text('sales@softstore.pk');
    await tester.scrollUntilVisible(emailFinder, 200);
    expect(emailFinder, findsOneWidget);
  });
}

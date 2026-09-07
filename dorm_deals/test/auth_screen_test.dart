import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dorm_deals/widgets/auth_screen.dart';

void main() {
  testWidgets('Authentication screen shows login fields', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));

    expect(find.text('Login'), findsWidgets);
    expect(find.byKey(const ValueKey('email-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('password-field')), findsOneWidget);
    expect(find.text('Create new account'), findsOneWidget);
  });

  testWidgets('Authentication screen switches to sign up mode', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));

    await tester.tap(find.text('Create new account'));
    await tester.pump();

    expect(find.text('Sign Up'), findsWidgets);
    expect(find.byKey(const ValueKey('repeat-password-field')), findsOneWidget);
    expect(find.text('I already have an account'), findsOneWidget);
  });

  testWidgets(
    'Authentication screen shows validation error for empty login fields',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AuthScreen()));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();

      expect(find.text('Please enter email and password'), findsOneWidget);
    },
  );

  testWidgets(
    'Authentication screen shows validation error when passwords differ in sign up mode',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AuthScreen()));

      await tester.tap(find.text('Create new account'));
      await tester.pump();

      await tester.enterText(
        find.byKey(const ValueKey('email-field')),
        'test@account.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('password-field')),
        'abcd1234',
      );
      await tester.enterText(
        find.byKey(const ValueKey('repeat-password-field')),
        '4321dcba',
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    },
  );
}

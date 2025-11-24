import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:deck_builder/data/view/login.dart';
import 'package:deck_builder/data/util/user_provider.dart';

void main() {
  group('LoginPage validation tests', () {
    testWidgets('Shows validation messages when fields empty and disables submit', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(),
          child: const MaterialApp(home: LoginPage()),
        ),
      );

      // Initially, should show Login button
      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);

      // Tap login without entering data
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      // After tapping, validation messages should appear for username and password
      expect(find.text('Please enter your username'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Toggling to Sign Up shows Email field and Create Account button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<UserProvider>(
          create: (_) => UserProvider(),
          child: const MaterialApp(home: LoginPage()),
        ),
      );

      // Tap the TextButton to switch to signup
      await tester.tap(find.text('No account? Sign up'));
      await tester.pumpAndSettle();

      expect(find.text('Email'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Create Account'), findsOneWidget);
    });
  });
}


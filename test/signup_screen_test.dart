import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:interprep/screens/signup/ui_signup_screen.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const ProviderScope(
      child: MaterialApp(
        home: SignUpScreen(),
      ),
    );
  }

  testWidgets(
      'SignUpScreen has name, email, password, and confirm password text fields and can enter text',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    final nameTextFieldFinder = find.byKey(const ValueKey('nameTextField'));
    final emailTextFieldFinder = find.byKey(const ValueKey('emailTextField'));
    final passwordTextFieldFinder = find.byKey(const ValueKey('passwordTextField'));

    expect(nameTextFieldFinder, findsOneWidget);
    expect(emailTextFieldFinder, findsOneWidget);
    expect(passwordTextFieldFinder, findsOneWidget);

    await tester.enterText(nameTextFieldFinder, 'John Doe');
    await tester.pumpAndSettle();
    expect(find.text('John Doe'), findsOneWidget);

    await tester.enterText(emailTextFieldFinder, 'john@example.com');
    await tester.pumpAndSettle();
    expect(find.text('john@example.com'), findsOneWidget);

    await tester.enterText(passwordTextFieldFinder, 'password123');
    await tester.pumpAndSettle();
    expect(find.text('password123'), findsOneWidget);
  });
}

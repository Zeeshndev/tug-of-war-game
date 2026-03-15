import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tug_of_war_mathematics/screens/profile_manage_screen.dart';

void main() {
  testWidgets('ProfileManageScreen requires Parent Gate math answer to unlock', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ProfileManageScreen()),
      ),
    );

    // Initial state should show the Parent Gate lock
    expect(find.text('Parent Gate'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget); // The math input field
    expect(find.text('Create New Profile'), findsNothing); // Should be hidden

    // We can't easily predict the random math answer in a black-box test without injecting a mock RNG,
    // so we test that entering a definitively wrong answer (like "99999") triggers the failure SnackBar.
    await tester.enterText(find.byType(TextField), '99999');
    await tester.tap(find.text('Unlock'));
    await tester.pump();

    // Verify error message appears
    expect(find.text('Incorrect. Try again!'), findsOneWidget);
  });
}
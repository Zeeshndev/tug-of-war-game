import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tug_of_war_mathematics/screens/result_screen.dart';
import 'package:tug_of_war_mathematics/providers/app_providers.dart';
import 'package:tug_of_war_mathematics/models/game_models.dart';

void main() {
  void setMobileScreenSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets('ResultScreen shows 3 stars and Next Level button on perfect win', (WidgetTester tester) async {
    setMobileScreenSize(tester);

    const mockSession = GameSession(
      playerScore: 10, aiScore: 5, starsEarned: 3,
      isNewRecord: true, coinsEarned: 25, sessionCorrect: 10,
      sessionAnswered: 10, active: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameProvider.overrideWith((ref) => MockGameNotifier(mockSession)),
          matchConfigProvider.overrideWith((ref) => {'isAdventure': true, 'level': 1, 'isBoss': false}),
        ],
        child: const MaterialApp(home: ResultScreen()),
      ),
    );

    // 🚨 FIX: Explicitly tick the Future.delayed timers forward to avoid pending timer crash
    await tester.pump(const Duration(milliseconds: 500)); // Initial delay
    await tester.pump(const Duration(milliseconds: 400)); // Star 1 delay
    await tester.pump(const Duration(milliseconds: 400)); // Star 2 delay
    await tester.pump(const Duration(milliseconds: 400)); // Star 3 delay
    await tester.pumpAndSettle(); // Finish any remaining visual animations

    expect(find.text('Level 1 Complete!'), findsOneWidget);
    expect(find.text('🎉 NEW RECORD! 🎉'), findsOneWidget);
    expect(find.text('Next Level ▶'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsWidgets);
  });

  testWidgets('ResultScreen shows Try Again button on loss', (WidgetTester tester) async {
    setMobileScreenSize(tester);

    const mockSession = GameSession(
      playerScore: 2, aiScore: 10, starsEarned: 0,
      isNewRecord: false, active: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameProvider.overrideWith((ref) => MockGameNotifier(mockSession)),
          matchConfigProvider.overrideWith((ref) => {'isAdventure': true, 'level': 1, 'isBoss': false}),
        ],
        child: const MaterialApp(home: ResultScreen()),
      ),
    );

    // 🚨 FIX: Explicitly tick the initial Future.delayed timer forward
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Level 1 Failed'), findsOneWidget);
    expect(find.text('Try Again 🔄'), findsOneWidget);
    expect(find.text('Next Level ▶'), findsNothing);
  });
}

class MockGameNotifier extends StateNotifier<GameSession> implements GameNotifier {
  MockGameNotifier(super.state);
  @override void appendDigit(String d) {}
  @override void deleteDigit() {}
  @override void submitAnswer() {}
  @override void pause() {}
  @override void resume() {}
  @override void forceEnd() {}
  @override void startMatch() {}
}
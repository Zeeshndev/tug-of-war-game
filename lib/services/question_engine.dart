import 'dart:math';
import '../models/game_models.dart';

class QuestionEngine {
  static final Random _rng = Random();

  static MathQuestion generate(String ageGroup, {required GameMode mode, int adventureLevel = 0}) {
    final skills = mode.skills;
    final skill = skills[_rng.nextInt(skills.length)];

    // DIFFICULTY SCALING LOGIC
    int maxVal;
    if (adventureLevel > 0) {
      if (adventureLevel <= 5) maxVal = 10;        // Easy
      else if (adventureLevel <= 10) maxVal = 25;  // Medium
      else if (adventureLevel <= 15) maxVal = 50;  // Hard
      else maxVal = 100;                           // Very Hard Boss Tier
    } else {
      // Standard Quick Play logic
      maxVal = ageGroup == 'A' ? 12 : 25;
    }

    int a, b, answer;
    String text;

    switch (skill) {
      case MathSkill.addition:
        a = _rng.nextInt(maxVal) + 1;
        b = _rng.nextInt(maxVal) + 1;
        answer = a + b;
        text = '$a + $b';
        break;
      case MathSkill.subtraction:
        a = _rng.nextInt(maxVal) + 5;
        b = _rng.nextInt(a) + 1;
        answer = a - b;
        text = '$a - $b';
        break;
      case MathSkill.multiplication:
        // Cap multiplication differently so it doesn't get impossible
        int mulMax = adventureLevel > 0 ? (adventureLevel <= 10 ? 9 : 15) : (ageGroup == 'A' ? 5 : 10);
        a = _rng.nextInt(mulMax) + 2;
        b = _rng.nextInt(mulMax) + 2;
        answer = a * b;
        text = '$a × $b';
        break;
      case MathSkill.division:
        int divMax = adventureLevel > 0 ? (adventureLevel <= 10 ? 9 : 15) : (ageGroup == 'A' ? 5 : 10);
        b = _rng.nextInt(divMax) + 2;
        answer = _rng.nextInt(divMax) + 2;
        a = b * answer;
        text = '$a ÷ $b';
        break;
    }

    return MathQuestion(
      displayText: text,
      correctAnswer: answer,
      skill: skill,
      generatedAt: DateTime.now(),
    );
  }

  static bool validate(String input, int correct) {
    if (input.isEmpty) return false;
    final val = int.tryParse(input);
    return val == correct;
  }

  static int generateWrongAnswer(int correct) {
    int offset = _rng.nextBool() ? (_rng.nextInt(3) + 1) : -(_rng.nextInt(3) + 1);
    int wrong = correct + offset;
    return wrong < 0 ? correct + 1 : wrong;
  }
}
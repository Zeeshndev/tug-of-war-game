import 'dart:math';
import '../models/game_models.dart';

class QuestionEngine {
  static final Random _rng = Random();

  static MathQuestion generate(String ageGroup, {GameMode mode = GameMode.mixed}) {
    List<MathSkill> allowed = List.from(mode.skills);

    // REMOVED the age override that was ignoring the user's game mode setting.
    // The engine now strictly obeys the selected Game Mode.
    if (allowed.isEmpty) allowed = [MathSkill.addition];
    
    final skill = allowed[_rng.nextInt(allowed.length)];
    return _buildQuestion(skill, ageGroup);
  }

  static MathQuestion _buildQuestion(MathSkill skill, String ageGroup) {
    if (ageGroup == 'A') {
      return _buildGroupA(skill);
    } else {
      return _buildGroupB(skill);
    }
  }

  static MathQuestion _buildGroupA(MathSkill skill) {
    // Group A (Ages 5-7): Now supports all modes, but with very simple numbers
    switch (skill) {
      case MathSkill.subtraction:
        final a = _r(5, 20);
        final b = _r(1, a);
        return MathQuestion(displayText: '$a − $b = ?', correctAnswer: a - b,
            skill: skill, generatedAt: DateTime.now());
      case MathSkill.multiplication:
        // Simple multiplication up to 5x5
        final a = _r(1, 5);
        final b = _r(1, 5);
        return MathQuestion(displayText: '$a × $b = ?', correctAnswer: a * b,
            skill: skill, generatedAt: DateTime.now());
      case MathSkill.division:
        // Simple division (e.g., 10 ÷ 2)
        final b = _r(1, 5);
        final answer = _r(1, 5);
        final a = b * answer;
        return MathQuestion(displayText: '$a ÷ $b = ?', correctAnswer: answer,
            skill: skill, generatedAt: DateTime.now());
      case MathSkill.addition:
      default:
        final a = _r(1, 15);
        final b = _r(1, 15);
        return MathQuestion(displayText: '$a + $b = ?', correctAnswer: a + b,
            skill: MathSkill.addition, generatedAt: DateTime.now());
    }
  }

  static MathQuestion _buildGroupB(MathSkill skill) {
    // Group B (Ages 8-11): Standard difficulty
    switch (skill) {
      case MathSkill.subtraction:
        final a = _r(20, 99);
        final b = _r(1, a);
        return MathQuestion(displayText: '$a − $b = ?', correctAnswer: a - b,
            skill: skill, generatedAt: DateTime.now());
      case MathSkill.multiplication:
        final a = _r(2, 12);
        final b = _r(2, 12);
        return MathQuestion(displayText: '$a × $b = ?', correctAnswer: a * b,
            skill: skill, generatedAt: DateTime.now());
      case MathSkill.division:
        final b = _r(2, 12);
        final answer = _r(2, 12);
        final a = b * answer;
        return MathQuestion(displayText: '$a ÷ $b = ?', correctAnswer: answer,
            skill: skill, generatedAt: DateTime.now());
      case MathSkill.addition:
      default:
        final a = _r(10, 99);
        final b = _r(10, 99);
        return MathQuestion(displayText: '$a + $b = ?', correctAnswer: a + b,
            skill: MathSkill.addition, generatedAt: DateTime.now());
    }
  }

  static int _r(int min, int max) {
    if (max <= min) return min;
    return min + _rng.nextInt(max - min + 1);
  }

  static bool validate(String input, int correct) {
    if (input.isEmpty) return false;
    final parsed = int.tryParse(input.trim());
    return parsed != null && parsed == correct;
  }

  static int generateWrongAnswer(int correct) {
    final offsets = [-4, -3, -2, -1, 1, 2, 3, 4, 5];
    return max(0, correct + offsets[Random().nextInt(offsets.length)]);
  }
}
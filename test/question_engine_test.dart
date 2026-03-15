import 'package:flutter_test/flutter_test.dart';
import 'package:tug_of_war_mathematics/services/question_engine.dart';
import 'package:tug_of_war_mathematics/models/game_models.dart';

void main() {
  group('QuestionEngine Tests', () {
    test('Generates valid addition questions for Age Group A', () {
      final q = QuestionEngine.generate('A', mode: GameMode.additionOnly);
      expect(q.skill, MathSkill.addition);
      expect(q.displayText.contains('+'), isTrue);
    });

    test('Generates valid subtraction questions for Age Group B', () {
      final q = QuestionEngine.generate('B', mode: GameMode.subtractionOnly);
      expect(q.skill, MathSkill.subtraction);
      expect(q.displayText.contains('-'), isTrue);
    });

    test('Generates mixed questions successfully', () {
      final q1 = QuestionEngine.generate('A', mode: GameMode.mixed);
      final q2 = QuestionEngine.generate('B', mode: GameMode.mixed);
      expect(q1.displayText, isNotEmpty);
      expect(q2.displayText, isNotEmpty);
    });

    test('Validates correct and incorrect answers', () {
      expect(QuestionEngine.validate('15', 15), isTrue);
      expect(QuestionEngine.validate('10', 15), isFalse);
      expect(QuestionEngine.validate('', 15), isFalse);
    });

    test('Generates plausible wrong answers for AI', () {
      final wrongAns = QuestionEngine.generateWrongAnswer(20);
      expect(wrongAns != 20, isTrue);
    });
  });
}
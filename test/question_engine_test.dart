import 'package:flutter_test/flutter_test.dart';
import 'package:tug_of_war_mathematics/services/question_engine.dart';
import 'package:tug_of_war_mathematics/models/game_models.dart';

void main() {
  group('QuestionEngine', () {
    test('Group A generates only addition/subtraction', () {
      for (int i = 0; i < 50; i++) {
        final q = QuestionEngine.generate('A');
        expect(
          q.skill == MathSkill.addition || q.skill == MathSkill.subtraction,
          true,
          reason: 'Group A should not include ${q.skill}',
        );
      }
    });

    test('Group B can generate all four operations', () {
      final skills = <MathSkill>{};
      for (int i = 0; i < 200; i++) {
        final q = QuestionEngine.generate('B');
        skills.add(q.skill);
      }
      expect(skills.length, 4, reason: 'Should see all 4 skills in Group B');
    });

    test('Answers are non-negative', () {
      for (int i = 0; i < 100; i++) {
        final q = QuestionEngine.generate('A');
        expect(q.correctAnswer, greaterThanOrEqualTo(0));
      }
    });

    test('Division produces clean whole numbers', () {
      for (int i = 0; i < 100; i++) {
        final q = QuestionEngine.generate('B');
        if (q.skill == MathSkill.division) {
          expect(q.correctAnswer, greaterThan(0));
        }
      }
    });

    test('validate() returns true for correct answer', () {
      final q = QuestionEngine.generate('A');
      expect(QuestionEngine.validate('${q.correctAnswer}', q.correctAnswer), true);
    });

    test('validate() returns false for wrong answer', () {
      expect(QuestionEngine.validate('999', 5), false);
    });

    test('validate() returns false for empty input', () {
      expect(QuestionEngine.validate('', 5), false);
    });

    test('generateWrongAnswer is never equal to correct', () {
      for (int i = 1; i <= 50; i++) {
        final wrong = QuestionEngine.generateWrongAnswer(i);
        expect(wrong, isNot(i));
      }
    });
  });
}

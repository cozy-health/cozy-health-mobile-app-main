import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/features/quiz/domain/clinical_assessment.dart';
import 'package:cozy_health/core/models/quiz_attempt.dart';

void main() {
  for (final assessment in ClinicalAssessment.all) {
    group(assessment.id, () {
      test('has the correct question count and score range', () {
        expect(assessment.questions.length, assessment.id == 'phq-9' ? 9 : 7);
        expect(
          assessment.score(List.filled(assessment.questions.length, 0)),
          0,
        );
        expect(
          assessment.score(List.filled(assessment.questions.length, 3)),
          assessment.id == 'phq-9' ? 27 : 21,
        );
      });
      final boundaries = assessment.id == 'phq-9'
          ? {
              0: 'Minimal',
              4: 'Minimal',
              5: 'Mild',
              9: 'Mild',
              10: 'Moderate',
              14: 'Moderate',
              15: 'Moderately Severe',
              19: 'Moderately Severe',
              20: 'Severe',
              27: 'Severe',
            }
          : {
              0: 'Minimal',
              4: 'Minimal',
              5: 'Mild',
              9: 'Mild',
              10: 'Moderate',
              14: 'Moderate',
              15: 'Severe',
              21: 'Severe',
            };
      for (final boundary in boundaries.entries) {
        test(
          'score ${boundary.key} is ${boundary.value}',
          () => expect(assessment.severity(boundary.key), boundary.value),
        );
      }
      test('rejects incomplete, extra and out-of-range answers', () {
        expect(() => assessment.score([0]), throwsArgumentError);
        expect(
          () =>
              assessment.score(List.filled(assessment.questions.length + 1, 0)),
          throwsArgumentError,
        );
        expect(
          () => assessment.score(List.filled(assessment.questions.length, -1)),
          throwsArgumentError,
        );
        expect(
          () => assessment.score(List.filled(assessment.questions.length, 4)),
          throwsArgumentError,
        );
        expect(() => assessment.severity(-1), throwsRangeError);
        expect(
          () => assessment.severity(assessment.maximumScore + 1),
          throwsRangeError,
        );
      });
      test('offers support at 15 independently of severity name', () {
        final answers = List.filled(assessment.questions.length, 0);
        for (var i = 0; i < 5; i++) {
          answers[i] = 3;
        }
        expect(assessment.needsSupport(answers), isTrue);
        answers[4] = 2;
        expect(assessment.needsSupport(answers), isFalse);
      });
    });
  }
  test('positive PHQ-9 self-harm answer offers support below 15', () {
    final answers = List.filled(9, 0)..[8] = 1;
    expect(ClinicalAssessment.phq9.score(answers), 1);
    expect(ClinicalAssessment.phq9.needsSupport(answers), isTrue);
  });
  test('unknown IDs do not silently become clinical instruments', () {
    expect(ClinicalAssessment.find('sleep'), isNull);
    expect(ClinicalAssessment.find('clinical'), isNull);
  });
  test(
    'result JSON preserves clinical identifiers, severity and private answers',
    () {
      final result = QuizAttempt(
        id: 'attempt',
        quizId: 'gad-7',
        quizSlug: 'gad-7',
        quizTitle: ClinicalAssessment.gad7.title,
        answers: List.filled(7, 3),
        score: 21,
        interpretation: 'Severe',
        severityLabel: 'Severe',
        isCrisisFlagged: true,
        completedAt: DateTime.utc(2026, 10, 9),
      );
      final json = result.toJson();
      expect(json['assessment_id'], 'gad-7');
      expect(json['quiz_slug'], 'gad-7');
      expect(json['total_score'], 21);
      expect(json['severity_label'], 'Severe');
      expect(json['interpretation'], 'Severe');
      expect(QuizAttempt.fromJson(json).severityLabel, 'Severe');
      expect(QuizAttempt.fromJson(json).answers, List.filled(7, 3));
    },
  );
  test(
    'legacy backend fields restore a severity label without rewriting old results',
    () {
      final result = QuizAttempt.fromJson({
        'id': 'saved',
        'quiz_slug': 'phq-9',
        'score': 15,
        'interpretation': 'Moderately Severe',
        'answers': List.filled(9, 0),
      });
      expect(result.assessmentId, 'phq-9');
      expect(result.severityLabel, 'Moderately Severe');
      final legacy = QuizAttempt.fromJson({
        'id': 'old',
        'quiz_slug': 'clinical',
        'score': 6,
        'interpretation': 'Previous mock interpretation',
      });
      expect(legacy.assessmentId, 'clinical');
      expect(legacy.severityLabel, '');
    },
  );
}

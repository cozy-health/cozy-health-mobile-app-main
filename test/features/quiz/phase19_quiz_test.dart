import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/core/models/quiz_attempt.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/services/user_data_merge.dart';
import 'package:cozy_health/core/storage/encrypted_hive.dart';
import 'package:cozy_health/features/quiz/data/quiz_invitation_service.dart';
import 'package:cozy_health/features/quiz/data/quiz_repository.dart';
import 'package:cozy_health/features/quiz/domain/clinical_assessment.dart';
import '../../support/repository_fixture.dart';
import 'assessment_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = RepositoryFixture<QuizAttempt>(
    LocalDbService.quizAttemptBoxName,
    QuizAttemptAdapter(),
  );
  setUpAll(() async {
    await fixture.open();
    await EncryptedHive.openBox<String>(LocalDbService.syncQueueBoxName);
  });
  setUp(() async {
    LocalDbService().syncPaused = true;
    await fixture.reset();
    await LocalDbService().syncQueueBox.clear();
  });
  tearDownAll(fixture.close);
  QuizAttempt provisional() => QuizAttempt(
    id: '00000000-0000-4000-8000-000000000010',
    quizId: 'gad-7',
    quizSlug: 'gad-7',
    quizTitle: 'Fixture',
    answers: List.generate(7, (i) => i * 10 + 101),
    score: 999,
    interpretation: 'Provisional',
    isCrisisFlagged: false,
    completedAt: DateTime.utc(2026, 10, 12),
    metadata: {
      'validation_state': 'pending',
      'definition_version': '00000000-0000-4000-8000-000000000001',
      'disclaimer_accepted': true,
    },
  );
  test(
    'canonical sync result is written before its durable operation is acknowledged',
    () async {
      final attempt = provisional();
      await QuizRepository().saveAttempt(attempt);
      final item = LocalDbService().pendingItems.single;
      fixture.body = {
        'data': {
          'results': [
            {
              'client_operation_id': item.id,
              'success': true,
              'record': {
                ...attempt.toJson(),
                'score': 7,
                'total_score': 7,
                'interpretation': 'Mild',
                'severity_label': 'Mild',
                'validated_at': '2026-10-13T10:00:00Z',
              },
            },
          ],
        },
      };
      LocalDbService().syncPaused = false;
      await LocalDbService().processSyncQueue(force: true);
      expect(fixture.box.get(attempt.id)!.score, 7);
      expect(fixture.box.get(attempt.id)!.isValidated, isTrue);
      expect(LocalDbService().pendingItems, isEmpty);
    },
  );
  test(
    'permanent quiz errors preserve answers and stop endless retries',
    () async {
      final attempt = provisional();
      await QuizRepository().saveAttempt(attempt);
      final item = LocalDbService().pendingItems.single;
      fixture.body = {
        'data': {
          'results': [
            {
              'client_operation_id': item.id,
              'success': false,
              'error_code': 'definition_unavailable',
            },
          ],
        },
      };
      LocalDbService().syncPaused = false;
      await LocalDbService().processSyncQueue(force: true);
      expect(fixture.box.get(attempt.id)!.validationState, 'rejected');
      expect(fixture.box.get(attempt.id)!.answers, attempt.answers);
      expect(LocalDbService().pendingItems, isEmpty);
    },
  );
  test(
    'canonical download overrides a newer provisional score and tombstones erase it',
    () async {
      final attempt = provisional();
      await fixture.box.put(attempt.id, attempt);
      await UserDataMerge().apply('quiz_attempt', {
        ...attempt.toJson(),
        'score': 7,
        'total_score': 7,
        'validated_at': '2026-10-12T00:00:00Z',
      });
      expect(fixture.box.get(attempt.id)!.score, 7);
      await UserDataMerge().apply('quiz_attempt', {
        'id': attempt.id,
        'is_deleted': true,
      });
      expect(fixture.box.get(attempt.id), isNull);
    },
  );
  test('versioned definitions preserve independent PHQ item 9 support', () {
    final definition = assessmentFixture(ClinicalAssessment.phq9);
    final assessment = ClinicalAssessment.fromDefinition(definition);
    final answers = List.generate(9, (i) => i * 10 + 100);
    answers[8] = 181;
    expect(assessment.score(answers), 1);
    expect(assessment.needsSupport(answers), isTrue);
  });
  test(
    'PSS reverse scoring and eight-question sleep use their own option scales',
    () {
      for (final slug in ['pss-10', 'sleep']) {
        final count = slug == 'pss-10' ? 10 : 8;
        final maximum = slug == 'pss-10' ? 4 : 3;
        final definition = {
          'slug': slug,
          'title': 'Synthetic $slug',
          'estimated_minutes': 4,
          'scoring_rules': {
            'bands': [
              {'max': count * maximum, 'label': 'Fixture'},
            ],
          },
          'questions': [
            for (var i = 0; i < count; i++)
              {
                'question': 'Fixture $i',
                'options': [
                  for (var j = 0; j <= maximum; j++)
                    {
                      'id': i * 10 + j,
                      'label': 'Option $j',
                      'score': slug == 'pss-10' && [4, 5, 7, 8].contains(i + 1)
                          ? 4 - j
                          : j,
                    },
                ],
              },
          ],
        };
        final assessment = ClinicalAssessment.fromDefinition(definition);
        expect(assessment.questions.length, count);
        expect(assessment.maximumScore, count * maximum);
        expect(
          assessment.score(List.generate(count, (i) => i * 10)),
          slug == 'pss-10' ? 16 : 0,
        );
        expect(
          assessment.needsSupport(List.generate(count, (i) => i * 10)),
          isFalse,
        );
      }
    },
  );
  test(
    'invitation routing only accepts the configured HTTPS host and token path',
    () {
      final token = List.filled(64, 'a').join();
      expect(
        QuizInvitationService.invitationToken(
          Uri.parse(
            'https://cozy-health-api-production.up.railway.app/quiz-invite/$token',
          ),
        ),
        token,
      );
      for (final link in [
        'http://cozy-health-api-production.up.railway.app/quiz-invite/$token',
        'https://attacker.example/quiz-invite/$token',
        'https://cozy-health-api-production.up.railway.app/quiz-invite/$token?next=evil',
      ]) {
        expect(QuizInvitationService.invitationToken(Uri.parse(link)), isNull);
      }
    },
  );
}

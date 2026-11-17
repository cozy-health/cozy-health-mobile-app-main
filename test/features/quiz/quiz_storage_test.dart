import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:cozy_health/core/storage/encrypted_hive.dart';
import 'package:cozy_health/core/models/quiz_attempt.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/features/quiz/data/quiz_repository.dart';
import '../../support/repository_fixture.dart';

// Recreates the existing nine-field format to verify upgrade compatibility.
class _LegacyAdapter extends QuizAttemptAdapter {
  @override
  void write(BinaryWriter writer, QuizAttempt obj) {
    final fields = [
      obj.id,
      obj.quizId,
      obj.quizSlug,
      obj.quizTitle,
      obj.answers,
      obj.score,
      obj.interpretation,
      obj.isCrisisFlagged,
      obj.completedAt,
    ];
    writer.writeByte(fields.length);
    for (var i = 0; i < fields.length; i++) {
      writer.writeByte(i);
      writer.write(fields[i]);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = RepositoryFixture<QuizAttempt>(
    LocalDbService.quizAttemptBoxName,
    QuizAttemptAdapter(),
  );
  late Box<String> queue;
  setUpAll(() async {
    await fixture.open();
    queue = await EncryptedHive.openBox<String>(
      LocalDbService.syncQueueBoxName,
    );
  });
  setUp(() async {
    await fixture.reset();
    await queue.clear();
    LocalDbService.instance.syncPaused = true;
  });
  tearDown(() {
    LocalDbService.instance.syncPaused = false;
  });
  tearDownAll(fixture.close);
  QuizAttempt result() => QuizAttempt(
    id: 'real-result',
    quizId: 'phq-9',
    quizSlug: 'phq-9',
    quizTitle: 'PHQ-9 Depression Screening',
    answers: [3, 3, 3, 3, 3, 0, 0, 0, 0],
    score: 15,
    interpretation: 'Moderately Severe',
    severityLabel: 'Moderately Severe',
    isCrisisFlagged: true,
    completedAt: DateTime.utc(2026, 10, 9),
  );
  test(
    'real result is encrypted locally and queued with real ID and severity',
    () async {
      await QuizRepository().saveAttempt(result());
      expect(fixture.box.get('real-result')!.assessmentId, 'phq-9');
      final intent = LocalDbService.instance.pendingItems.single;
      expect(intent.type, 'quiz_attempt');
      expect(intent.payload!['quiz_slug'], 'phq-9');
      expect(intent.payload!['score'], 15);
      expect(intent.payload!['interpretation'], 'Moderately Severe');
      expect(intent.payload!['answers'], [3, 3, 3, 3, 3, 0, 0, 0, 0]);
      await fixture.box.close();
      fixture.box = await EncryptedHive.openBox<QuizAttempt>(
        LocalDbService.quizAttemptBoxName,
      );
      expect(
        fixture.box.get('real-result')!.severityLabel,
        'Moderately Severe',
      );
    },
  );
  test(
    'existing nine-field Hive records remain readable after upgrade',
    () async {
      Hive.registerAdapter<QuizAttempt>(_LegacyAdapter(), override: true);
      await fixture.box.put('legacy', result());
      await fixture.box.close();
      Hive.registerAdapter<QuizAttempt>(QuizAttemptAdapter(), override: true);
      fixture.box = await EncryptedHive.openBox<QuizAttempt>(
        LocalDbService.quizAttemptBoxName,
      );
      final restored = fixture.box.get('legacy')!;
      expect(restored.score, 15);
      expect(restored.answers, [3, 3, 3, 3, 3, 0, 0, 0, 0]);
      expect(restored.severityLabel, '');
      expect(restored.interpretation, 'Moderately Severe');
    },
  );
}

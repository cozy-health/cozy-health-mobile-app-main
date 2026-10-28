import 'package:cozy_health/core/repositories/home_repository.dart';
import 'package:cozy_health/core/repositories/streak_repository.dart';
import 'package:cozy_health/core/storage/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/endpoint_fixture.dart';
import 'streak_progress_test.dart' show baseline;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixture = EndpointFixture();
  var account = '1';
  StreakRepository repository() =>
      StreakRepository(api: HomeRepository(), account: () => account);
  setUpAll(fixture.open);
  setUp(() async {
    await fixture.reset();
    account = '1';
    fixture.body = {'data': baseline().toJson()};
  });
  tearDownAll(fixture.close);

  test(
    'new repository instance restores typed confirmed progress without HTTP',
    () async {
      await repository().fetch();
      final requestCount = fixture.requests.length;
      final restored = await repository().cached();
      expect(restored?.currentDays, 7);
      expect(restored?.restDays, 1);
      expect(restored?.earningStarts, '2026-10-01');
      expect(restored?.creditedSources, hasLength(7));
      expect(fixture.requests, hasLength(requestCount));
    },
  );

  test(
    'saved progress is inaccessible to another account or after logout',
    () async {
      await repository().fetch();
      account = '2';
      expect(await repository().cached(), isNull);
      await TokenStorage().saveToken('2|new-account');
      expect(await repository().cached(), isNull);
      await TokenStorage().clearToken();
      expect(await repository().cached(), isNull);
    },
  );

  test(
    'wrong-account API response is rejected and malformed cache can refresh',
    () async {
      account = '2';
      await expectLater(repository().fetch(), throwsStateError);
      expect(await repository().cached(), isNull);
      account = '1';
      fixture.body = {
        'data': {'current_days': 7},
      };
      await HomeRepository().fetchStreak();
      expect(await repository().cached(), isNull);
      fixture.body = {'data': baseline().toJson()};
      expect((await repository().fetch()).restDays, 1);
    },
  );
}

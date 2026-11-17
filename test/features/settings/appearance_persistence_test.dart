import 'package:cozy_health/core/models/user_profile.dart';
import 'package:cozy_health/core/services/local_db_service.dart';
import 'package:cozy_health/core/storage/encrypted_hive.dart';
import 'package:cozy_health/features/settings/data/profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/repository_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final local = LocalDbService();
  final fixture = RepositoryFixture<UserProfile>(
    LocalDbService.userProfileBoxName,
    UserProfileAdapter(),
  );

  setUp(() async {
    await fixture.open();
    await local.settingsBox();
    await EncryptedHive.openBox<String>(LocalDbService.syncQueueBoxName);
    local.syncPaused = true;
  });
  tearDown(() async {
    await local.waitForSyncIdle();
    local.syncPaused = false;
    await fixture.close();
  });

  test(
    'all appearance preferences survive closing and reopening encrypted storage',
    () async {
      final repository = ProfileRepository();
      await repository.updateField('theme', 'dark');
      await repository.updateField('accentColor', '4282090230');
      await repository.updateField('textSize', 1.3);
      await repository.updateField('highContrast', true);
      await repository.updateField('reduceMotion', true);
      final profileName = local.boxName(LocalDbService.userProfileBoxName);
      final settingsName = local.boxName(LocalDbService.userSettingsBoxName);
      await local.userProfileBox.close();
      await (await local.settingsBox()).close();
      await EncryptedHive.openBox<UserProfile>(profileName);
      await EncryptedHive.openBox<dynamic>(settingsName);
      final restarted = await ProfileRepository().watchProfile().first;
      expect(restarted!.theme, 'dark');
      expect(restarted.accentColor, '4282090230');
      expect(restarted.textSize, 1.3);
      expect(restarted.highContrast, isTrue);
      expect(restarted.reduceMotion, isTrue);
    },
  );
}

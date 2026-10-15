import '../../../core/api/api_client.dart';
import '../../../core/models/next_of_kin_contact.dart';
import '../../../core/services/local_db_service.dart';

/// Contact changes may sync later. Help requests are never stored or queued.
class NextOfKinRepository {
  final _local = LocalDbService();
  static const storageKey = 'next_of_kin';

  Future<NextOfKinContact?> load() async {
    final value = (await _local.settingsBox()).get(storageKey);
    final contact = value is Map ? value['contact'] : null;
    return contact is Map
        ? NextOfKinContact.fromJson(Map<String, dynamic>.from(contact))
        : null;
  }

  Future<void> save(NextOfKinContact? contact) async {
    if (contact != null) {
      contact = NextOfKinContact(
        name: contact.name.trim(),
        phone: NextOfKinContact.normalizePhone(contact.phone),
        relationship: contact.relationship.trim(),
      );
    }
    if (contact != null &&
        (contact.name.trim().isEmpty ||
            contact.name.length > 100 ||
            contact.relationship.length > 100 ||
            !NextOfKinContact.validPhone(contact.phone))) {
      throw const FormatException('Invalid next-of-kin contact');
    }
    final scope = _local.boxName(LocalDbService.userSettingsBoxName);
    final box = await _local.settingsBox();
    if (scope != _local.boxName(LocalDbService.userSettingsBoxName)) {
      throw StateError('Account changed');
    }
    final value = {
      'id': 'primary',
      'contact': contact?.toJson(),
      'client_updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    // Queue first: a failed local write cannot silently discard the sync intent.
    await _local.enqueueSync(
      type: 'next_of_kin',
      action: contact == null ? 'delete' : 'upsert',
      recordId: 'primary',
      payload: {
        'id': 'primary',
        ...?contact?.toJson(),
        'client_updated_at': value['client_updated_at'],
      },
    );
    await box.put(storageKey, value);
    _local.processSyncQueue();
  }

  Future<void> refresh() async {
    final scope = _local.boxName(LocalDbService.userSettingsBoxName);
    final response = await ApiClient.instance.get('/next-of-kin');
    if (scope != _local.boxName(LocalDbService.userSettingsBoxName)) return;
    await merge(
      response.data['data'] == null
          ? null
          : Map<String, dynamic>.from(response.data['data'] as Map),
    );
  }

  Future<void> merge(Map<String, dynamic>? incoming) async {
    final scope = _local.boxName(LocalDbService.userSettingsBoxName);
    final box = await _local.settingsBox();
    if (scope != _local.boxName(LocalDbService.userSettingsBoxName)) return;
    // Unacknowledged local edits and removals always win over a download.
    if (_local.hasPending('next_of_kin', 'primary')) return;
    final stored = box.get(storageKey);
    final localTime = stored is Map
        ? DateTime.tryParse(stored['client_updated_at']?.toString() ?? '')
        : null;
    final remoteTime = DateTime.tryParse(
      incoming?['client_updated_at']?.toString() ?? '',
    );
    if (localTime != null &&
        (remoteTime == null || remoteTime.isBefore(localTime))) {
      return;
    }
    if (incoming == null) {
      await box.delete(storageKey);
    } else {
      final contact = incoming['contact'];
      if (contact != null) {
        NextOfKinContact.fromJson(Map<String, dynamic>.from(contact as Map));
      }
      await box.put(storageKey, incoming);
    }
  }
}

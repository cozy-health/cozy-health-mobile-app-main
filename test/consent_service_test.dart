import 'package:flutter_test/flutter_test.dart';
import 'package:cozy_health/core/services/consent_service.dart';

Map<String, dynamic> document({
  String version = 'draft-0.1',
  bool published = false,
  bool required = true,
}) => {
  'title': 'Privacy Policy',
  'version': version,
  'published': published,
  'required': required,
  'content': published ? 'Approved test document.' : null,
};

void main() {
  test('first draft tracking never accepts marketing or legal text', () async {
    final posts = <Map<String, dynamic>>[];
    final service = ConsentService(
      token: () async => 'session',
      get: (path) async => path == '/config'
          ? {
              'consent': {
                'enforce_blocking': false,
                'documents': {
                  'privacy_policy': document(),
                  'marketing': document(required: false),
                },
              },
            }
          : {'owner_id': 1, 'data': []},
      post: (body) async {
        posts.add(body);
        return {
          'owner_id': 1,
          'data': {...body, 'status': 'pre_acceptance', 'accepted_at': null},
        };
      },
    );
    final state = (await service.load())!;
    expect(posts, hasLength(1));
    expect(posts.single['document_type'], 'privacy_policy');
    expect(posts.single['accepted'], false);
    expect(state.pending, isEmpty);
    expect(state.marketingAllowed, false);
  });

  test(
    'version changes are skippable until published blocking configuration',
    () {
      final draft = ConsentDocument(
        'privacy_policy',
        document(version: 'draft-0.2'),
      );
      final real = ConsentDocument(
        'privacy_policy',
        document(version: '1.0', published: true),
      );
      final marketing = ConsentDocument(
        'marketing',
        document(version: '1.0', published: true),
      );
      final state = ConsentState(
        ownerId: 1,
        documents: [draft, real, marketing],
        records: [],
        enforceBlocking: true,
      );
      expect(state.blocking(draft), false);
      expect(state.blocking(real), true);
      expect(state.blocking(marketing), false);
      expect(state.pending.map((doc) => doc.type), [
        'privacy_policy',
        'privacy_policy',
      ]);
    },
  );

  test('account switch prevents consent submission from old screen', () async {
    var token = 'first';
    var submitted = 0;
    final service = ConsentService(
      token: () async => token,
      get: (path) async => path == '/config'
          ? {
              'consent': {
                'enforce_blocking': false,
                'documents': {'marketing': document(required: false)},
              },
            }
          : {'owner_id': 1, 'data': []},
      post: (body) async {
        submitted++;
        return {};
      },
    );
    final state = (await service.load())!;
    token = 'second';
    await expectLater(service.marketing(state, true), throwsStateError);
    expect(submitted, 0);
  });

  test(
    'marketing choice persists only after explicit submission and can be withdrawn',
    () async {
      final service = ConsentService(
        token: () async => 'session',
        get: (path) async => path == '/config'
            ? {
                'consent': {
                  'enforce_blocking': false,
                  'documents': {'marketing': document(required: false)},
                },
              }
            : {'owner_id': 1, 'data': []},
        post: (body) async => {
          'owner_id': 1,
          'data': {
            ...body,
            'status': body['accepted'] == true ? 'accepted' : 'withdrawn',
          },
        },
      );
      final state = (await service.load())!;
      expect(state.marketingAllowed, false);
      await service.marketing(state, true);
      expect(state.marketingAllowed, true);
      await service.marketing(state, false);
      expect(state.marketingAllowed, false);
    },
  );
}

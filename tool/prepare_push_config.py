"""Prepare optional Firebase build configuration without exposing values in logs."""
import json
import os
import plistlib
import subprocess
import sys
from urllib.parse import urlparse
from pathlib import Path


def prepare_production_android():
    config = json.loads(os.environ['PRODUCTION_ANDROID_FIREBASE_JSON'])
    info = config.get('project_info', {})
    if info.get('project_id') != 'cozy-health-prod-2026' or str(info.get('project_number')) != '398026710363':
        raise ValueError('Expected the approved production Firebase project')
    clients = [client for client in config.get('client', [])
               if client.get('client_info', {}).get('android_client_info', {}).get('package_name') == 'org.cozyhealth.app']
    if len(clients) != 1:
        raise ValueError('Expected exactly one production Android registration')
    client = clients[0]
    if client['client_info'].get('mobilesdk_app_id') != '1:398026710363:android:1da10014dbd344477d4e7e':
        raise ValueError('Production Firebase app identity differs from the registered app')
    server_clients = {oauth.get('client_id') for oauth in client.get('oauth_client', [])
                      if oauth.get('client_type') == 3}
    if len(server_clients) != 1:
        raise ValueError('Production Google sign-in requires one configured server OAuth client')
    server_client = server_clients.pop()
    if not isinstance(server_client, str) or not server_client.startswith('398026710363-') or not server_client.endswith('.apps.googleusercontent.com'):
        raise ValueError('Server OAuth client must belong to the production project')
    api_key = client.get('api_key', [{}])[0].get('current_key')
    if not isinstance(api_key, str) or not api_key:
        raise ValueError('Production Firebase API key is missing')
    dsn = os.environ.get('SENTRY_DSN_PRODUCTION', '').strip()
    parsed = urlparse(dsn)
    if (parsed.scheme != 'https' or parsed.hostname != 'o4512334056128512.ingest.de.sentry.io'
            or parsed.path != '/4512362638147664' or not parsed.username
            or parsed.password or parsed.query or parsed.fragment or parsed.port):
        raise ValueError('Expected the existing converted production mobile Sentry project')
    analytics_key = os.environ.get('POSTHOG_KEY_PRODUCTION', '').strip()
    if analytics_key and (not analytics_key.startswith('phc_') or any(c.isspace() for c in analytics_key)):
        raise ValueError('Production analytics project key is invalid')
    android = {'apiKey': api_key, 'appId': client['client_info']['mobilesdk_app_id'],
               'messagingSenderId': str(info['project_number']), 'projectId': info['project_id']}
    defines = {'COZY_ENVIRONMENT': 'production', 'INTERNAL_TEST_BUILD': 'false', 'COZY_DEMO': 'false',
               'PLAY_DEVELOPMENT_BUILD': 'false', 'FIREBASE_OPTIONS': json.dumps({'android': android}),
               'GOOGLE_CLIENT_ID': server_client, 'SENTRY_DSN': dsn, 'TELEMETRY_ENVIRONMENT': 'production',
               'PRODUCTION_TELEMETRY_ENABLED': 'true', 'POSTHOG_KEY': analytics_key,
               'POSTHOG_HOST': 'https://us.i.posthog.com'}
    config['client'] = [client]
    Path('android/app/google-services.json').write_text(json.dumps(config))
    Path('push-defines.json').write_text(json.dumps(defines))
    print('Production Android registration, OAuth and reporting configuration verified.')


target = os.environ.get('COZY_BUILD_TARGET', 'development')
if target == 'production-android':
    prepare_production_android()
    sys.exit(0)
if target != 'development':
    raise ValueError('Unsupported build configuration target')

raw = os.environ.get('FIREBASE_OPTIONS_JSON', '')
defines = {'FIREBASE_OPTIONS': ''}
google_xcconfig = Path('ios/Flutter/GoogleDevelopment.generated.xcconfig')
google_xcconfig.unlink(missing_ok=True)
# Development telemetry is independent of Firebase. Never inherit production keys.
defines.update(SENTRY_DSN='', POSTHOG_KEY='', POSTHOG_HOST='https://us.i.posthog.com',
               TELEMETRY_ENVIRONMENT='disabled')
dsn = os.environ.get('SENTRY_DSN_DEV', '').strip()
analytics_key = os.environ.get('POSTHOG_KEY_DEV', '').strip()
if dsn:
    parsed = urlparse(dsn)
    if (parsed.scheme != 'https' or parsed.hostname != 'o4512334056128512.ingest.de.sentry.io'
            or parsed.path != '/4512362638147664' or not parsed.username
            or parsed.password or parsed.query or parsed.fragment or parsed.port):
        raise ValueError('Sentry DSN must identify the approved development mobile project')
    defines['SENTRY_DSN'] = dsn
if analytics_key:
    if not analytics_key.startswith('phc_') or any(c.isspace() for c in analytics_key):
        raise ValueError('PostHog development project key is invalid')
    defines['POSTHOG_KEY'] = analytics_key
if dsn or analytics_key:
    defines['TELEMETRY_ENVIRONMENT'] = 'development'
if raw:
    options = json.loads(raw)
    for platform in ('android', 'ios'):
        for field in ('apiKey', 'appId', 'messagingSenderId', 'projectId'):
            if not isinstance(options[platform].get(field), str) or not options[platform][field]:
                raise ValueError(f'Missing Firebase field: {platform}.{field}')
    defines['FIREBASE_OPTIONS'] = json.dumps(options, separators=(',', ':'))
    if options['android']['projectId'] != options['ios']['projectId']:
        raise ValueError('Android and iOS Firebase projects must match for this build')
    android = options['android']
    # Public OAuth identifiers from the owner-supplied development Firebase file.
    # Keep other projects and configuration-free builds unconfigured.
    google_clients = []
    ios_google = {}
    if android['projectId'] == 'cozy-health-dev-2026':
        server_client = '412988470560-uitjnofphvuedeoag59u2dpm8ef0cepr.apps.googleusercontent.com'
        android_client = '412988470560-hi8gd9r1r5teb2q56k75nbvseqdv9omt.apps.googleusercontent.com'
        defines.update(GOOGLE_CLIENT_ID=server_client, GOOGLE_ANDROID_CLIENT_ID=android_client)
        ios_client = '412988470560-slgb2nk4q2qkqaguesoqvfd6o97rrba2.apps.googleusercontent.com'
        reversed_client = '.'.join(reversed(ios_client.split('.')))
        defines['GOOGLE_IOS_CLIENT_ID'] = ios_client
        ios_google = {'CLIENT_ID': ios_client, 'REVERSED_CLIENT_ID': reversed_client}
        google_clients = [
            {'client_id': android_client, 'client_type': 1, 'android_info': {
                'package_name': 'com.example.cozy_health',
                'certificate_hash': '00218bc875065a936cb8c151e172b25b00fcbdbc'}},
            {'client_id': server_client, 'client_type': 3},
        ]
    android_config = {
        'project_info': {'project_number': android['messagingSenderId'], 'project_id': android['projectId']},
        'client': [{
            'client_info': {'mobilesdk_app_id': android['appId'], 'android_client_info': {'package_name': 'com.example.cozy_health'}},
            'api_key': [{'current_key': android['apiKey']}],
            'oauth_client': google_clients,
            'services': {'appinvite_service': {'other_platform_oauth_client': []}},
        }],
        'configuration_version': '1',
    }
    Path('android/app/google-services.json').write_text(json.dumps(android_config))
    ios = options['ios']
    if not ios.get('iosBundleId'):
        raise ValueError('Missing Firebase iosBundleId')
    if ios['iosBundleId'] != 'com.example.cozyHealth':
        raise ValueError('Firebase iOS bundle ID must match the existing app')
    if ios_google:
        google_xcconfig.parent.mkdir(parents=True, exist_ok=True)
        google_xcconfig.write_text('GOOGLE_REVERSED_CLIENT_ID = ' + reversed_client + '\n')
    plist = {'API_KEY': ios['apiKey'], 'GOOGLE_APP_ID': ios['appId'],
             'GCM_SENDER_ID': ios['messagingSenderId'], 'PROJECT_ID': ios['projectId'],
             'BUNDLE_ID': ios['iosBundleId'], 'PLIST_VERSION': '1',
             'IS_GCM_ENABLED': True, 'IS_ANALYTICS_ENABLED': False}
    plist.update(ios_google)
    Path('ios/Runner/GoogleService-Info.plist').write_bytes(plistlib.dumps(plist))
    if sys.platform == 'darwin':
        subprocess.run(['ruby', '-rxcodeproj', '-e', '''
          project = Xcodeproj::Project.open('ios/Runner.xcodeproj')
          group = project.main_group.find_subpath('Runner', false)
          ref = group.files.find { |f| f.path == 'GoogleService-Info.plist' } || group.new_file('GoogleService-Info.plist')
          phase = project.targets.find { |t| t.name == 'Runner' }.resources_build_phase
          phase.add_file_reference(ref, true) unless phase.files_references.include?(ref)
          project.save
        '''], check=True)
    print('Firebase client configuration prepared. This does not enable Apple signing.')
else:
    # A configuration-free build must not inherit a previous Firebase project.
    for generated in ('android/app/google-services.json', 'ios/Runner/GoogleService-Info.plist'):
        Path(generated).unlink(missing_ok=True)
    print('Firebase configuration absent: building with push delivery unavailable.')
Path('push-defines.json').write_text(json.dumps(defines))

"""Prepare the separate Play development identity; never select production."""
import json
import os
from pathlib import Path
import runpy

PROJECT = 'cozy-health-dev-2026'
PACKAGE = 'org.cozyhealth.app.dev'
APP_ID = '1:412988470560:android:09e562ad84991433e21345'


def select_client(config):
    if config.get('project_info', {}).get('project_id') != PROJECT:
        raise ValueError('Play development requires the approved development Firebase project')
    matches = [client for client in config.get('client', [])
               if client.get('client_info', {}).get('android_client_info', {}).get('package_name') == PACKAGE]
    if len(matches) != 1 or matches[0]['client_info']['mobilesdk_app_id'] != APP_ID:
        raise ValueError('Expected exactly one approved Play development Firebase app')
    return matches[0]


def main():
    config = json.loads(os.environ['PLAY_DEVELOPMENT_FIREBASE_JSON'])
    client = select_client(config)
    options = json.loads(os.environ['FIREBASE_OPTIONS_JSON'])
    if any(options[platform]['projectId'] != PROJECT for platform in ('android', 'ios')):
        raise ValueError('Mixed Firebase environments are forbidden')
    info = config['project_info']
    options['android'] = {'apiKey': client['api_key'][0]['current_key'], 'appId': APP_ID,
                          'messagingSenderId': info['project_number'], 'projectId': PROJECT}
    if info.get('storage_bucket'):
        options['android']['storageBucket'] = info['storage_bucket']
    os.environ['FIREBASE_OPTIONS_JSON'] = json.dumps(options)
    runpy.run_path(str(Path(__file__).with_name('prepare_push_config.py')), run_name='__main__')
    # Preserve the selected registration, including future Play signing OAuth clients.
    config['client'] = [client]
    Path('android/app/google-services.json').write_text(json.dumps(config))
    defines = json.loads(Path('push-defines.json').read_text())
    defines.pop('GOOGLE_ANDROID_CLIENT_ID', None)  # SDK uses serverClientId; Play's client is certificate-bound.
    defines.update(COZY_ENVIRONMENT='development', INTERNAL_TEST_BUILD='true', PLAY_DEVELOPMENT_BUILD='true')
    Path('push-defines.json').write_text(json.dumps(defines))
    print('Play development package, Firebase app and environment verified.')


if __name__ == '__main__':
    main()

import json
import os
from pathlib import Path
import runpy
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / 'prepare_push_config.py'


class ProductionAndroidConfigTest(unittest.TestCase):
    def config(self):
        return {'project_info': {'project_id': 'cozy-health-prod-2026', 'project_number': '398026710363'},
                'client': [{'client_info': {
                    'mobilesdk_app_id': '1:398026710363:android:1da10014dbd344477d4e7e',
                    'android_client_info': {'package_name': 'org.cozyhealth.app'}},
                    'api_key': [{'current_key': 'fixture'}],
                    'oauth_client': [{'client_type': 3, 'client_id': '398026710363-fixture.apps.googleusercontent.com'}]}]}

    def prepare(self, config):
        with patch.dict(os.environ, {
            'COZY_BUILD_TARGET': 'production-android',
            'PRODUCTION_ANDROID_FIREBASE_JSON': json.dumps(config),
            'SENTRY_DSN_PRODUCTION': 'https://fixture@o4512334056128512.ingest.de.sentry.io/4512362638147664',
            'SENTRY_DSN_DEV': 'must-not-inherit', 'POSTHOG_KEY_DEV': 'must-not-inherit',
        }):
            try:
                runpy.run_path(str(SCRIPT), run_name='__main__')
            except SystemExit as result:
                if result.code != 0:
                    raise

    def test_production_uses_registered_identity_and_server_oauth_client(self):
        previous = Path.cwd()
        with tempfile.TemporaryDirectory() as temporary:
            try:
                os.chdir(temporary)
                Path('android/app').mkdir(parents=True)
                self.prepare(self.config())
                defines = json.loads(Path('push-defines.json').read_text())
                self.assertEqual(defines['COZY_ENVIRONMENT'], 'production')
                self.assertEqual(defines['INTERNAL_TEST_BUILD'], 'false')
                self.assertEqual(defines['GOOGLE_CLIENT_ID'], self.config()['client'][0]['oauth_client'][0]['client_id'])
                self.assertEqual(defines['TELEMETRY_ENVIRONMENT'], 'production')
                self.assertEqual(defines['POSTHOG_KEY'], '')
                self.assertEqual(json.loads(defines['FIREBASE_OPTIONS'])['android']['projectId'], 'cozy-health-prod-2026')
                self.assertFalse(Path('ios/Runner/GoogleService-Info.plist').exists())
            finally:
                os.chdir(previous)

    def test_rejects_missing_oauth_and_wrong_project_or_package(self):
        for field in ('oauth', 'project', 'package'):
            config = self.config()
            if field == 'oauth':
                config['client'][0]['oauth_client'] = []
            elif field == 'project':
                config['project_info']['project_id'] = 'cozy-health-dev-2026'
            else:
                config['client'][0]['client_info']['android_client_info']['package_name'] = 'org.cozyhealth.app.dev'
            with self.subTest(field=field), self.assertRaises(ValueError):
                self.prepare(config)

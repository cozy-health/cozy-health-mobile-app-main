import json
import os
from pathlib import Path
import runpy
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / 'prepare_push_config.py'


class PushConfigTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.previous = Path.cwd()
        os.chdir(self.temp.name)
        Path('ios/Runner').mkdir(parents=True)
        Path('android/app').mkdir(parents=True)

    def tearDown(self):
        os.chdir(self.previous)
        self.temp.cleanup()

    def run_config(self, raw):
        with patch.dict(os.environ, {'FIREBASE_OPTIONS_JSON': raw}), patch('sys.platform', 'win32'):
            runpy.run_path(str(SCRIPT), run_name='__main__')

    def options(self):
        return {platform: {'apiKey': 'fixture-key', 'appId': 'fixture-app', 'messagingSenderId': '123',
                           'projectId': 'fixture-project', **({'iosBundleId': 'com.example.cozyHealth'} if platform == 'ios' else {})}
                for platform in ('android', 'ios')}

    def test_platform_configurations_match_selected_project(self):
        self.run_config(json.dumps(self.options()))
        android = json.loads(Path('android/app/google-services.json').read_text())
        self.assertEqual(android['project_info']['project_id'], 'fixture-project')
        self.assertEqual(android['client'][0]['client_info']['android_client_info']['package_name'], 'com.example.cozy_health')
        self.assertTrue(Path('ios/Runner/GoogleService-Info.plist').exists())
        self.assertEqual(json.loads(json.loads(Path('push-defines.json').read_text())['FIREBASE_OPTIONS'])['ios']['projectId'], 'fixture-project')

    def test_absent_configuration_removes_previous_native_files(self):
        self.run_config(json.dumps(self.options()))
        self.run_config('')
        self.assertFalse(Path('android/app/google-services.json').exists())
        self.assertFalse(Path('ios/Runner/GoogleService-Info.plist').exists())
        self.assertEqual(json.loads(Path('push-defines.json').read_text())['FIREBASE_OPTIONS'], '')

    def test_mixed_projects_are_rejected(self):
        options = self.options()
        options['android']['projectId'] = 'other-project'
        with self.assertRaises(ValueError):
            self.run_config(json.dumps(options))

    def test_google_development_ids_survive_native_config_regeneration(self):
        options = self.options()
        for platform in ('android', 'ios'):
            options[platform]['projectId'] = 'cozy-health-dev-2026'
        self.run_config(json.dumps(options))
        defines = json.loads(Path('push-defines.json').read_text())
        clients = json.loads(Path('android/app/google-services.json').read_text())['client'][0]['oauth_client']
        server = next(client for client in clients if client['client_type'] == 3)
        android = next(client for client in clients if client['client_type'] == 1)
        self.assertEqual(defines['GOOGLE_CLIENT_ID'], server['client_id'])
        self.assertNotEqual(defines['GOOGLE_CLIENT_ID'], android['client_id'])
        self.assertEqual(android['android_info']['certificate_hash'], '00218bc875065a936cb8c151e172b25b00fcbdbc')
        self.assertNotIn('GOOGLE_IOS_CLIENT_ID', defines)
        # Switching away must not retain development OAuth configuration.
        for raw in (json.dumps(self.options()), ''):
            self.run_config(raw)
            defines = json.loads(Path('push-defines.json').read_text())
            self.assertNotIn('GOOGLE_CLIENT_ID', defines)
            self.assertNotIn('GOOGLE_ANDROID_CLIENT_ID', defines)

    def test_development_telemetry_is_available_without_firebase(self):
        with patch.dict(os.environ, {'SENTRY_DSN_DEV': 'https://fixture@o4512334056128512.ingest.de.sentry.io/4512362638147664',
                                     'POSTHOG_KEY_DEV': 'phc_fixture'}):
            self.run_config('')
        defines = json.loads(Path('push-defines.json').read_text())
        self.assertEqual(defines['TELEMETRY_ENVIRONMENT'], 'development')
        self.assertEqual(defines['POSTHOG_HOST'], 'https://us.i.posthog.com')
        self.assertEqual(defines['POSTHOG_KEY'], 'phc_fixture')
        self.assertTrue(defines['SENTRY_DSN'].endswith('/4512362638147664'))

    def test_telemetry_does_not_inherit_generic_or_production_keys(self):
        with patch.dict(os.environ, {'SENTRY_DSN_DEV': '', 'POSTHOG_KEY_DEV': '',
                                     'SENTRY_DSN': 'production', 'POSTHOG_KEY': 'production'}):
            self.run_config('')
        defines = json.loads(Path('push-defines.json').read_text())
        self.assertEqual(defines['SENTRY_DSN'], '')
        self.assertEqual(defines['POSTHOG_KEY'], '')
        self.assertEqual(defines['TELEMETRY_ENVIRONMENT'], 'disabled')

    def test_wrong_sentry_project_and_invalid_analytics_key_are_rejected(self):
        for dsn, key in [('https://fixture@o4512334056128512.ingest.de.sentry.io/production', ''),
                         ('https://fixture@attacker.example/4512362638147664', ''),
                         ('', 'personal_api_secret')]:
            with self.subTest(dsn=dsn, key=key), patch.dict(os.environ, {'SENTRY_DSN_DEV': dsn, 'POSTHOG_KEY_DEV': key}):
                with self.assertRaises(ValueError):
                    self.run_config('')


if __name__ == '__main__':
    unittest.main()

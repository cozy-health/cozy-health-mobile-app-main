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


if __name__ == '__main__':
    unittest.main()

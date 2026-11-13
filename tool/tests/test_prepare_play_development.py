import importlib.util
import unittest
import json
import os
import tempfile
from unittest.mock import patch
from pathlib import Path

spec = importlib.util.spec_from_file_location('play', Path(__file__).parents[1] / 'prepare_play_development.py')
play = importlib.util.module_from_spec(spec)
spec.loader.exec_module(play)


class PlayDevelopmentTest(unittest.TestCase):
    def config(self):
        return {'project_info': {'project_id': play.PROJECT}, 'client': [
            {'client_info': {'mobilesdk_app_id': play.APP_ID,
                             'android_client_info': {'package_name': play.PACKAGE}}}]}

    def test_selects_only_registered_development_identity(self):
        config = self.config()
        self.assertEqual(play.select_client(config), config['client'][0])
        for field, value in [('project', 'cozy-health-prod-2026'), ('package', 'com.example.cozy_health'), ('app', 'wrong')]:
            config = self.config()
            if field == 'project':
                config['project_info']['project_id'] = value
            elif field == 'package':
                config['client'][0]['client_info']['android_client_info']['package_name'] = value
            else:
                config['client'][0]['client_info']['mobilesdk_app_id'] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                play.select_client(config)

    def test_duplicate_registration_rejected(self):
        config = self.config()
        config['client'] *= 2
        with self.assertRaises(ValueError):
            play.select_client(config)

    def test_build_configuration_uses_play_firebase_without_changing_ios(self):
        config = self.config()
        config['project_info']['project_number'] = '412988470560'
        config['client'][0]['api_key'] = [{'current_key': 'fixture'}]
        config['client'][0]['oauth_client'] = []
        options = {platform: dict(apiKey='fixture', appId='original', messagingSenderId='412988470560',
                                 projectId=play.PROJECT, **({'iosBundleId': 'com.example.cozyHealth'} if platform == 'ios' else {}))
                   for platform in ('android', 'ios')}
        previous = Path.cwd()
        with tempfile.TemporaryDirectory() as temp, patch.dict(os.environ, {
                'PLAY_DEVELOPMENT_FIREBASE_JSON': json.dumps(config), 'FIREBASE_OPTIONS_JSON': json.dumps(options),
                'SENTRY_DSN_DEV': '', 'POSTHOG_KEY_DEV': ''}), patch('sys.platform', 'win32'):
            try:
                os.chdir(temp)
                Path('android/app').mkdir(parents=True)
                Path('ios/Runner').mkdir(parents=True)
                play.main()
                defines = json.loads(Path('push-defines.json').read_text())
                firebase = json.loads(defines['FIREBASE_OPTIONS'])
                self.assertEqual(firebase['android']['appId'], play.APP_ID)
                self.assertEqual(firebase['ios'], options['ios'])
                self.assertEqual(defines['COZY_ENVIRONMENT'], 'development')
                self.assertEqual(defines['INTERNAL_TEST_BUILD'], 'true')
                self.assertEqual(defines['PLAY_DEVELOPMENT_BUILD'], 'true')
                self.assertEqual(json.loads(Path('android/app/google-services.json').read_text())['client'][0], config['client'][0])
                self.assertNotIn('GOOGLE_ANDROID_CLIENT_ID', defines)
                options['ios']['projectId'] = 'production'
                os.environ['FIREBASE_OPTIONS_JSON'] = json.dumps(options)
                with self.assertRaises(ValueError):
                    play.main()
            finally:
                os.chdir(previous)

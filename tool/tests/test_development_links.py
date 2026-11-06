"""Native link registration must match links issued by the development API."""
from pathlib import Path
import plistlib
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
ANDROID = '{http://schemas.android.com/apk/res/android}'


class DevelopmentLinksTest(unittest.TestCase):
    def test_android_registers_development_quiz_invitation_origin(self):
        manifest = ET.parse(ROOT / 'android/app/src/main/AndroidManifest.xml')
        hosts = [node.get(ANDROID + 'host') for node in manifest.findall('.//intent-filter/data')
                 if node.get(ANDROID + 'pathPrefix') == '/quiz-invite/']
        self.assertIn('api-dev.cozyhealth.org', hosts)

    def test_ios_registers_development_associated_domain(self):
        with (ROOT / 'ios/Runner/Runner.entitlements').open('rb') as stream:
            entitlements = plistlib.load(stream)
        self.assertIn('applinks:api-dev.cozyhealth.org', entitlements['com.apple.developer.associated-domains'])

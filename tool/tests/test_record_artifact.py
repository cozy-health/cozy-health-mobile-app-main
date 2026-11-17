import importlib.util
from pathlib import Path
import plistlib
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import zipfile

spec = importlib.util.spec_from_file_location('record_artifact', Path(__file__).resolve().parents[1] / 'record_artifact.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ArtifactIdentityTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.artifact = Path(self.temp.name) / 'app.apk'
        self.artifact.write_bytes(b'abc')

    def test_checksum_and_verified_android_certificate(self):
        certificate = 'a' * 64
        result = subprocess.CompletedProcess([], 0, 'Signer #1 certificate SHA-256 digest: ' + certificate + '\n')
        with patch.object(module.subprocess, 'run', return_value=result) as run:
            data = module.artifact_identity(self.artifact, 'android', 'apksigner', certificate)
        self.assertEqual(data['sha256'], 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad')
        self.assertEqual(data['certificate_sha256'], certificate)
        self.assertEqual(data['installed_upgrade_compatibility'], 'unverified')
        self.assertTrue(run.call_args.kwargs['check'])

    def test_wrong_or_ambiguous_android_certificate_is_rejected(self):
        for output in ['', 'Signer #1 certificate SHA-256 digest: ' + 'b' * 64,
                       'Signer #1 certificate SHA-256 digest: ' + 'a' * 64 + '\nSigner #2 certificate SHA-256 digest: ' + 'a' * 64]:
            with self.subTest(output=output), patch.object(module.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, output)):
                with self.assertRaises(ValueError):
                    module.artifact_identity(self.artifact, 'android', 'apksigner', 'a' * 64)

    def test_invalid_signature_is_rejected(self):
        with patch.object(module.subprocess, 'run', side_effect=subprocess.CalledProcessError(1, 'apksigner')):
            with self.assertRaises(subprocess.CalledProcessError):
                module.artifact_identity(self.artifact, 'android', 'apksigner')

    def test_ios_identity_comes_from_packaged_app(self):
        with zipfile.ZipFile(self.artifact, 'w') as archive:
            archive.writestr('Payload/Runner.app/Info.plist', plistlib.dumps({'CFBundleIdentifier': 'com.example.cozyHealth', 'CFBundleShortVersionString': '1.0', 'CFBundleVersion': '42'}))
        data = module.artifact_identity(self.artifact, 'ios')
        self.assertEqual(data['bundle_id'], 'com.example.cozyHealth')
        self.assertEqual(data['build'], '42')
        self.assertEqual(data['signing'], 'unsigned-requires-sideloadly')

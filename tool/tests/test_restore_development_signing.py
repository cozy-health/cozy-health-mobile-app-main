import base64
import hashlib
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('development_signing', Path(__file__).resolve().parents[1] / 'restore_development_signing.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class DevelopmentSigningTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.target = Path(self.temp.name) / 'debug.keystore'
        self.target.write_bytes(b'previous-key')
        self.encoded = base64.b64encode(b'fixture-keystore').decode()
        self.expected = hashlib.sha256(b'fixture-certificate').hexdigest()
        pem = base64.b64encode(b'fixture-certificate').decode()
        self.result = subprocess.CompletedProcess([], 0, '-----BEGIN CERTIFICATE-----\n'+pem+'\n-----END CERTIFICATE-----')

    def test_restores_only_a_verified_key(self):
        with patch.object(module.subprocess, 'run', return_value=self.result) as run:
            module.restore_keystore(self.encoded, self.expected, self.target)
        self.assertEqual(self.target.read_bytes(), b'fixture-keystore')
        self.assertTrue(run.call_args.kwargs['check'])
        self.assertIn('androiddebugkey', run.call_args.args[0])

    def test_missing_or_invalid_configuration_preserves_existing_key(self):
        for encoded, expected in [('', self.expected), (self.encoded, ''), ('invalid!', self.expected)]:
            with self.subTest(encoded=encoded), self.assertRaises(ValueError):
                module.restore_keystore(encoded, expected, self.target)
            self.assertEqual(self.target.read_bytes(), b'previous-key')

    def test_wrong_certificate_preserves_existing_key_and_cleans_temporary_file(self):
        with patch.object(module.subprocess, 'run', return_value=self.result):
            with self.assertRaises(ValueError):
                module.restore_keystore(self.encoded, 'a'*64, self.target)
        self.assertEqual(self.target.read_bytes(), b'previous-key')
        self.assertEqual(list(self.target.parent.iterdir()), [self.target])

    def test_invalid_keystore_preserves_existing_key(self):
        with patch.object(module.subprocess, 'run', side_effect=subprocess.CalledProcessError(1, 'keytool')):
            with self.assertRaises(subprocess.CalledProcessError):
                module.restore_keystore(self.encoded, self.expected, self.target)
        self.assertEqual(self.target.read_bytes(), b'previous-key')

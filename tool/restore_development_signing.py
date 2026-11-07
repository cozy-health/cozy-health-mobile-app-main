"""Restore the approved development-only Android debug key without logging it."""
import base64
import hashlib
import os
from pathlib import Path
import re
import subprocess
import tempfile


def restore_keystore(encoded, expected, target, keytool='keytool'):
    if not encoded or not re.fullmatch(r'[a-fA-F0-9]{64}', expected or ''):
        raise ValueError('Development keystore and approved certificate fingerprint are required')
    content = base64.b64decode(encoded, validate=True)
    if not content:
        raise ValueError('Development keystore is empty')
    target = Path(target)
    target.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=target.parent, delete=False) as stream:
            temporary = Path(stream.name)
            stream.write(content)
        result = subprocess.run([keytool, '-list', '-rfc', '-keystore', str(temporary),
                                 '-storepass', 'android', '-alias', 'androiddebugkey'],
                                check=True, capture_output=True, text=True)
        certificates = re.findall(r'-----BEGIN CERTIFICATE-----\s*(.*?)\s*-----END CERTIFICATE-----',
                                  result.stdout, re.DOTALL)
        if len(certificates) != 1:
            raise ValueError('Expected one development signing certificate')
        certificate = base64.b64decode(re.sub(r'\s', '', certificates[0]), validate=True)
        if hashlib.sha256(certificate).hexdigest() != expected.lower():
            raise ValueError('Keystore does not match the approved development certificate')
        temporary.chmod(0o600)
        os.replace(temporary, target)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def main():
    location = os.environ.get('COZY_ANDROID_DEVELOPMENT_KEYSTORE', '')
    if not location or not Path(location).is_absolute():
        raise ValueError('An absolute development keystore path shared with Gradle is required')
    restore_keystore(os.environ.get('ANDROID_DEVELOPMENT_KEYSTORE_BASE64', ''),
                     os.environ.get('ANDROID_DEVELOPMENT_CERT_SHA256', ''),
                     Path(location))
    print('Approved development signing identity restored; no key material logged.')


if __name__ == '__main__':
    main()

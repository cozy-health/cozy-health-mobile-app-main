"""Attach independently inspectable sideload artifact identity to build-info.json."""
import argparse
import hashlib
import json
from pathlib import Path
import plistlib
import re
import subprocess
import zipfile


def artifact_identity(artifact, platform, apksigner=None, expected_certificate=None):
    checksum = hashlib.sha256()
    with artifact.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            checksum.update(block)
    digest = checksum.hexdigest()
    identity = {'platform': platform, 'filename': artifact.name,
                'sha256': digest, 'size_bytes': artifact.stat().st_size}
    if platform == 'android':
        if not apksigner:
            raise ValueError('Android artifacts require apksigner verification')
        result = subprocess.run([apksigner, 'verify', '--print-certs', str(artifact)],
                                check=True, capture_output=True, text=True)
        certificates = re.findall(r'^Signer #\d+ certificate SHA-256 digest: ([a-fA-F0-9]{64})$',
                                  result.stdout, re.MULTILINE)
        if len(certificates) != 1:
            raise ValueError('Expected exactly one APK signing certificate')
        certificate = certificates[0].lower()
        if expected_certificate and certificate != expected_certificate.lower():
            raise ValueError('APK certificate differs from the approved development identity')
        identity.update(certificate_sha256=certificate, signing='development',
                        installed_upgrade_compatibility='unverified')
    else:
        with zipfile.ZipFile(artifact) as archive:
            info = plistlib.loads(archive.read('Payload/Runner.app/Info.plist'))
        identity.update(bundle_id=info['CFBundleIdentifier'],
                        version=info['CFBundleShortVersionString'],
                        build=info['CFBundleVersion'], signing='unsigned-requires-sideloadly',
                        installed_upgrade_compatibility='unverified')
    return identity


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--platform', choices=['android', 'ios'], required=True)
    parser.add_argument('--artifact', type=Path, required=True)
    parser.add_argument('--apksigner')
    parser.add_argument('--expected-certificate')
    args = parser.parse_args()
    manifest = Path('build-info.json')
    data = json.loads(manifest.read_text())
    data['artifact'] = artifact_identity(args.artifact, args.platform, args.apksigner,
                                         args.expected_certificate)
    manifest.write_text(json.dumps(data, indent=2) + '\n')
    print('Artifact checksum and signing identity recorded in build-info.json.')


if __name__ == '__main__':
    main()

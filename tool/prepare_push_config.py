"""Prepare optional Firebase build configuration without exposing values in logs."""
import json
import os
import plistlib
import subprocess
import sys
from pathlib import Path

raw = os.environ.get('FIREBASE_OPTIONS_JSON', '')
defines = {'FIREBASE_OPTIONS': ''}
if raw:
    options = json.loads(raw)
    for platform in ('android', 'ios'):
        for field in ('apiKey', 'appId', 'messagingSenderId', 'projectId'):
            if not isinstance(options[platform].get(field), str) or not options[platform][field]:
                raise ValueError(f'Missing Firebase field: {platform}.{field}')
    defines['FIREBASE_OPTIONS'] = json.dumps(options, separators=(',', ':'))
    ios = options['ios']
    if not ios.get('iosBundleId'):
        raise ValueError('Missing Firebase iosBundleId')
    if ios['iosBundleId'] != 'com.example.cozyHealth':
        raise ValueError('Firebase iOS bundle ID must match the existing app')
    plist = {'API_KEY': ios['apiKey'], 'GOOGLE_APP_ID': ios['appId'],
             'GCM_SENDER_ID': ios['messagingSenderId'], 'PROJECT_ID': ios['projectId'],
             'BUNDLE_ID': ios['iosBundleId'], 'PLIST_VERSION': '1',
             'IS_GCM_ENABLED': True, 'IS_ANALYTICS_ENABLED': False}
    Path('ios/Runner/GoogleService-Info.plist').write_bytes(plistlib.dumps(plist))
    if sys.platform == 'darwin':
        subprocess.run(['ruby', '-rxcodeproj', '-e', '''
          project = Xcodeproj::Project.open('ios/Runner.xcodeproj')
          group = project.main_group.find_subpath('Runner', false)
          ref = group.files.find { |f| f.path == 'GoogleService-Info.plist' } || group.new_file('GoogleService-Info.plist')
          phase = project.targets.find { |t| t.name == 'Runner' }.resources_build_phase
          phase.add_file_reference(ref, true) unless phase.files_references.include?(ref)
          project.save
        '''], check=True)
    print('Firebase client configuration prepared. This does not enable Apple signing.')
else:
    print('Firebase configuration absent: building with push delivery unavailable.')
Path('push-defines.json').write_text(json.dumps(defines))

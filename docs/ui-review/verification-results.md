# Final verification

| Check | Result |
|---|---|
| flutter analyze; flutter analyze --no-fatal-infos --no-fatal-warnings | 0 errors; 2 existing warnings and 9 existing infos outside scoped app changes. Default command exits 1 for these accepted warnings/infos; nonfatal variant exits 0. |
| flutter analyze --no-pub lib/features/home | No issues found |
| flutter test | 476 passed (474 existing + 2 heading contrast checks), exit 0 |
| Layout/offline/interaction regression group | 85 passed (83 existing + 2 heading contrast checks), included in full suite |
| flutter build apk --debug | Succeeded, exit 0; final rebuild 101.3 seconds |
| iOS | Local gate waived by user. No final-step local iOS build attempted. GitHub CI macOS workflow is the source of truth. |
| git diff --check | Passed |
| Physical device | Gate waived for this push; user will verify after push. Automated viewports are accepted but are not a substitute for physical-device evidence. |
| Existing quiz tests | 42 passed |
| Quiz History heading contrast | 2 passed; both headings meet at least 4.5:1 contrast in light and dark mode |
| Commit/push | Authorized once local checks pass; iOS/device gates waived for this push |

APK: `build/app/outputs/flutter-apk/app-debug.apk`. The build emits existing Gradle/AGP/Kotlin future-support warnings. No Android build configuration was changed.

iOS verification is delegated to `.github/workflows/build-ios.yml` (`macos-14`, triggered by pushes to `develop`). CI completion is separate from the waived local push gate.

Known limitations accepted for this push: Community actions remain session-local with no backend persistence; Demo Mode remains CLI-only (`--dart-define=COZY_DEMO=true`), with no Settings toggle; clipboard sharing does not open a native share sheet. Settings sub-screens remain out of scope.

## Existing static-analysis findings

```text
warning - 'attachViewHierarchy' is experimental and could be removed or changed at any time - test\core\crash_reporting_test.dart:111:22 - experimental_member_use
warning - The member 'future' can only be used within instance members of subclasses of '_BaseHandler' - test\core\sensitive_logging_test.dart:35:35 - invalid_use_of_protected_member
   info - Statements in an if should be enclosed in a block. Try wrapping the statement in a block - test\features\auth\restore_flow_test.dart:69:7 - curly_braces_in_flow_control_structures
   info - Statements in an if should be enclosed in a block. Try wrapping the statement in a block - test\features\auth\restore_flow_test.dart:326:13 - curly_braces_in_flow_control_structures
   info - Statements in an if should be enclosed in a block. Try wrapping the statement in a block - test\features\auth\restore_flow_test.dart:477:11 - curly_braces_in_flow_control_structures
   info - The import of 'dart:typed_data' is unnecessary because all of the used elements are also provided by the import of 'package:flutter/services.dart'. Try removing the import directive - test\features\home\feature_tour_test.dart:4:8 - unnecessary_import
   info - The import of 'dart:typed_data' is unnecessary because all of the used elements are also provided by the import of 'package:flutter/services.dart'. Try removing the import directive - test\support\local_fonts.dart:2:8 - unnecessary_import
   info - Unnecessary 'const' keyword. Try removing the keyword - third_party\flutter_jailbreak_detection\lib\flutter_jailbreak_detection.dart:7:7 - unnecessary_const
   info - Can't use a relative path to import a library in 'lib'. Try fixing the relative path or changing the import to a 'package:' import - tool\verify_debug_api.dart:2:8 - avoid_relative_lib_imports
   info - Can't use a relative path to import a library in 'lib'. Try fixing the relative path or changing the import to a 'package:' import - tool\verify_debug_api.dart:3:8 - avoid_relative_lib_imports
   info - Don't invoke 'print' in production code. Try using a logging framework - tool\verify_debug_api.dart:14:5 - avoid_print
```

See [full report](report.md), [file list](files-changed.md), [testing guide](testing-guide.md), and [SVG inventory](svg-inventory.md).

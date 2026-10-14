$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$sourceFiles = @(Get-ChildItem -LiteralPath (Join-Path $projectRoot 'lib') -Recurse -File -Filter '*.dart' | Sort-Object FullName)
$inventory = [System.Collections.Generic.List[string]]::new()
$overlays = [System.Collections.Generic.List[string]]::new()
$notices = [System.Collections.Generic.List[string]]::new()
$inventory.Add('# Full mobile app source inventory')
$inventory.Add('')
$inventory.Add('Generated 2026-10-10. Source inventory and review cues, not proof of visual or interaction correctness. Every screen file and additional screen/view class is listed. Counts are search matches, not defect counts. See full-app-audit.md for verified findings and coverage limits.')
$inventory.Add('')
$inventory.Add('| File | Screen/view classes | Explicit palette references | Motion expressions | Overlay calls | Empty handlers |')
$inventory.Add('| --- | --- | ---: | ---: | ---: | ---: |')
$overlays.Add('# Overlay call-site inventory')
$overlays.Add('')
$overlays.Add('Generated 2026-10-10. Every direct showDialog/showModalBottomSheet/showMenu/showGeneralDialog/showBottomSheet call in lib is listed with opening arguments. Indirect/custom overlays and snackbar sites are listed separately below or in full-app-notices.md. Absence of animationStyle in this excerpt alone is a review cue, not proof of a motion defect.')
$notices.Add('# Notification, snackbar, and transient feedback inventory')
$notices.Add('')
$notices.Add('Generated 2026-10-10. Source locations for transient feedback, banners, permission sheets, and dialog actions. This is a search-based inventory; message truthfulness findings are in full-app-audit.md.')
$screenCount = 0
foreach ($sourceFile in $sourceFiles) {
  $relative = $sourceFile.FullName.Substring($projectRoot.Length + 1).Replace('\', '/')
  $sourceText = Get-Content -LiteralPath $sourceFile.FullName -Raw -Encoding UTF8
  $sourceLines = @(Get-Content -LiteralPath $sourceFile.FullName -Encoding UTF8)
  $classes = @([regex]::Matches($sourceText, 'class\s+([A-Z]\w*(?:Screen|View))\s+extends') | ForEach-Object { $_.Groups[1].Value })
  if ($relative -match '/screens?/[^/]+\.dart$' -or $classes.Count -gt 0) {
    $screenCount++
    $palette = [regex]::Matches($sourceText, 'AppColors\.|Colors\.(?!transparent)|Color\(0x').Count
    $motion = [regex]::Matches($sourceText, 'AnimationController\(|TweenAnimationBuilder|Animated[A-Z]|animateTo|animateToPage').Count
    $popup = [regex]::Matches($sourceText, 'show(?:Dialog|ModalBottomSheet|Menu|GeneralDialog|BottomSheet)(?:<[^>]+>)?\(').Count
    $empty = [regex]::Matches($sourceText, 'on(?:Pressed|Tap):\s*\(\)\s*\{\s*(?://[^\r\n]*\s*)?\}').Count
    $inventory.Add("| [$relative](../../$relative) | $($classes -join ', ') | $palette | $motion | $popup | $empty |")
  }
  for ($lineIndex = 0; $lineIndex -lt $sourceLines.Count; $lineIndex++) {
    $line = $sourceLines[$lineIndex]
    if ($line -match 'show(?:Dialog|ModalBottomSheet|Menu|GeneralDialog|BottomSheet)(?:<[^>]+>)?\(') {
      $overlays.Add('')
      $overlays.Add("## ${relative}:$($lineIndex + 1)")
      $overlays.Add('')
      $overlays.Add('```dart')
      $overlays.AddRange([string[]]$sourceLines[$lineIndex..([Math]::Min($lineIndex + 12, $sourceLines.Count - 1))])
      $overlays.Add('```')
    }
    if ($line -match 'AppSnackbar\.(?:show|success|error|info|warning|saved|fromLegacy)|showAuthToast\(|showSnackBar\(|SnackBar\(|NotificationPermissionSheet|NotificationDeniedSheet|AppNotificationBanner|OfflineStatusBanner|FriendlyError\(') {
      $notices.Add("- [${relative}:$($lineIndex + 1)](../../${relative}): ``$($line.Trim().Replace('`',''))``")
    }
    if ($line -match 'showLicensePage\(|PopupMenuButton|Tooltip\(|OverlayEntry|Overlay\.of') {
      $overlays.Add('')
      $overlays.Add("Additional framework/custom overlay reference: [${relative}:$($lineIndex + 1)](../../${relative}) - ``$($line.Trim().Replace('`',''))``")
    }
  }
}
$inventory.Add('')
$inventory.Add("Source files scanned: $($sourceFiles.Count).")
$outputDir = Join-Path $projectRoot 'docs/ui-review'
[IO.File]::WriteAllLines((Join-Path $outputDir 'full-app-screen-inventory.md'), $inventory)
[IO.File]::WriteAllLines((Join-Path $outputDir 'full-app-overlay-inventory.md'), $overlays)
[IO.File]::WriteAllLines((Join-Path $outputDir 'full-app-notices.md'), $notices)
Write-Output "Scanned $($sourceFiles.Count) Dart source files. Screen rows: $screenCount. Overlay calls: $(($overlays | Where-Object { $_ -like '## *' }).Count). Notice references: $($notices.Count - 3)."

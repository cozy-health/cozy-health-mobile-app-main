param([Parameter(Mandatory=$true)][string]$Source)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
[xml]$document = Get-Content -LiteralPath $Source -Raw
$nodes = @($document.DocumentElement.ChildNodes | Where-Object NodeType -eq 'Element')
$entries = @(
  @{name='anxiety'; from=3; to=4; view='8 49 61 40'; defs=$true},
  @{name='burnout'; from=8; to=33; view='192 48 50 45'; defs=$false},
  @{name='wellbeing'; from=66; to=95; view='190 186 68 57'; defs=$false},
  @{name='gratitude'; from=99; to=163; view='10 335 80 50'; defs=$false}
)
foreach ($entry in $entries) {
  $body = ($nodes[$entry.from..$entry.to] | ForEach-Object OuterXml) -join "`n"
  $defs = if ($entry.defs) { $nodes[-1].OuterXml } else { '' }
  $content = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="'+$entry.view+'">'+$body+$defs+'</svg>'
  [IO.File]::WriteAllText((Join-Path $root "assets/svg/recommended_$($entry.name).svg"), $content)
}
@{source=(Split-Path $Source -Leaf);sha256=(Get-FileHash -LiteralPath $Source -Algorithm SHA256).Hash;exports=$entries} | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $root 'docs/design/recommended-artwork-export.json')

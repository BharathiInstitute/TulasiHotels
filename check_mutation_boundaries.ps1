$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

$scanPaths = @(
  'lib/features',
  'lib/shared',
  'lib/core'
)

$filePattern = '\.(dart)$'
$forbiddenPathPattern = '(?i)(screens|widgets)'
$allowedPathPattern = '(?i)(services|providers|models|test|features/customer/screens)'
$forbiddenWritePattern = '(FirebaseFirestore\.instance|_firestore|\.collection\(|\.doc\().*(\.set\(|\.update\(|\.delete\(|\.add\()'

$violations = New-Object System.Collections.Generic.List[string]

foreach ($scanPath in $scanPaths) {
  if (-not (Test-Path $scanPath)) {
    continue
  }

  Get-ChildItem -Path $scanPath -Recurse -File |
    Where-Object { $_.FullName -match $filePattern } |
    ForEach-Object {
      $relativePath = Resolve-Path -Relative $_.FullName
      $normalizedPath = $relativePath -replace '^\.\\', '' -replace '\\', '/'

      if ($normalizedPath -notmatch $forbiddenPathPattern) {
        return
      }

      if ($normalizedPath -match $allowedPathPattern) {
        return
      }

      $matches = Select-String -Path $_.FullName -Pattern $forbiddenWritePattern -AllMatches
      foreach ($match in $matches) {
        $violations.Add("${normalizedPath}:$($match.LineNumber): $($match.Line.Trim())")
      }
    }
}

if ($violations.Count -gt 0) {
  Write-Host 'Forbidden Firestore mutation calls found outside approved service/provider layers:' -ForegroundColor Red
  $violations | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
  exit 1
}

Write-Host 'No forbidden Firestore mutation calls found in screens/widgets.' -ForegroundColor Green
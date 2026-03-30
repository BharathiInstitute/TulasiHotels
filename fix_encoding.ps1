# Fix double-encoded UTF-8 in all Dart files
# Double-encoding happens when UTF-8 bytes are misread as Latin-1 and re-encoded
# 3-byte UTF-8 char (E0-EF xx xx) becomes 6 bytes: C3 [A0-AF] C2 [80-BF] C2 [80-BF]
# 4-byte UTF-8 char (F0-F7 xx xx xx) becomes 8 bytes: C3 [B0-B7] C2 [80-BF] C2 [80-BF] C2 [80-BF]

Set-StrictMode -Version Latest

$dartFiles = Get-ChildItem -Path 'd:\TulasiHotels\lib' -Filter '*.dart' -Recurse
$totalFixed = 0
$fixedFiles = @()

foreach ($file in $dartFiles) {
    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    $output = New-Object System.Collections.Generic.List[byte] -ArgumentList ($bytes.Length)
    $modified = $false
    $replacements = 0
    $i = 0
    
    while ($i -lt $bytes.Length) {
        # Check for double-encoded 4-byte UTF-8 (8 bytes -> 4 bytes)
        if ($i + 7 -lt $bytes.Length -and
            $bytes[$i] -eq 0xC3 -and $bytes[$i+1] -ge 0xB0 -and $bytes[$i+1] -le 0xB7 -and
            $bytes[$i+2] -eq 0xC2 -and $bytes[$i+3] -ge 0x80 -and $bytes[$i+3] -le 0xBF -and
            $bytes[$i+4] -eq 0xC2 -and $bytes[$i+5] -ge 0x80 -and $bytes[$i+5] -le 0xBF -and
            $bytes[$i+6] -eq 0xC2 -and $bytes[$i+7] -ge 0x80 -and $bytes[$i+7] -le 0xBF) {
            
            $b1 = [byte]($bytes[$i+1] + 0x40)
            # Validate: F0 requires second byte >= 90
            if ($b1 -eq 0xF0 -and $bytes[$i+3] -lt 0x90) {
                $output.Add($bytes[$i]); $i++; continue
            }
            $output.Add($b1)
            $output.Add($bytes[$i+3])
            $output.Add($bytes[$i+5])
            $output.Add($bytes[$i+7])
            $i += 8
            $modified = $true
            $replacements++
        }
        # Check for double-encoded 3-byte UTF-8 (6 bytes -> 3 bytes)
        elseif ($i + 5 -lt $bytes.Length -and
                $bytes[$i] -eq 0xC3 -and $bytes[$i+1] -ge 0xA0 -and $bytes[$i+1] -le 0xAF -and
                $bytes[$i+2] -eq 0xC2 -and $bytes[$i+3] -ge 0x80 -and $bytes[$i+3] -le 0xBF -and
                $bytes[$i+4] -eq 0xC2 -and $bytes[$i+5] -ge 0x80 -and $bytes[$i+5] -le 0xBF) {
            
            $b1 = [byte]($bytes[$i+1] + 0x40)
            # Validate: E0 requires second byte >= A0
            if ($b1 -eq 0xE0 -and $bytes[$i+3] -lt 0xA0) {
                $output.Add($bytes[$i]); $i++; continue
            }
            $output.Add($b1)
            $output.Add($bytes[$i+3])
            $output.Add($bytes[$i+5])
            $i += 6
            $modified = $true
            $replacements++
        }
        else {
            $output.Add($bytes[$i])
            $i++
        }
    }
    
    if ($modified) {
        [System.IO.File]::WriteAllBytes($file.FullName, $output.ToArray())
        $totalFixed++
        $fixedFiles += "$($file.Name) ($replacements fixes)"
    }
}

Write-Output "Fixed $totalFixed files total"
Write-Output "---"
foreach ($f in $fixedFiles) { Write-Output $f }

# Fix Windows-1252 double-encoded UTF-8 in all Dart files
# This handles the case where UTF-8 bytes were misread as Windows-1252, then re-encoded to UTF-8

$win1252 = [System.Text.Encoding]::GetEncoding(1252)
$utf8 = [System.Text.Encoding]::UTF8

# Build reverse map: Unicode codepoint -> Windows-1252 byte value
$reverseMap = @{}
for ($b = 0; $b -le 0xFF; $b++) {
    try {
        $ch = $win1252.GetString([byte[]]@($b))
        $cp = [int][char]$ch
        if (-not $reverseMap.ContainsKey($cp)) {
            $reverseMap[$cp] = $b
        }
    } catch {}
}

function Fix-Mojibake([string]$text) {
    $result = New-Object System.Text.StringBuilder($text.Length)
    $i = 0
    $fixes = 0
    
    while ($i -lt $text.Length) {
        $ch = $text[$i]
        $cp = [int]$ch
        
        # Check if this char maps back to a UTF-8 leading byte (C0-F7)
        if ($reverseMap.ContainsKey($cp)) {
            $firstByte = $reverseMap[$cp]
            
            $expectedCont = 0
            if ($firstByte -ge 0xC2 -and $firstByte -le 0xDF) { $expectedCont = 1 }
            elseif ($firstByte -ge 0xE0 -and $firstByte -le 0xEF) { $expectedCont = 2 }
            elseif ($firstByte -ge 0xF0 -and $firstByte -le 0xF4) { $expectedCont = 3 }
            
            if ($expectedCont -gt 0) {
                # Try to collect continuation characters
                $originalBytes = New-Object System.Collections.Generic.List[byte]
                $originalBytes.Add([byte]$firstByte)
                $valid = $true
                $charsConsumed = 1
                
                for ($j = 0; $j -lt $expectedCont; $j++) {
                    $nextIdx = $i + $charsConsumed
                    if ($nextIdx -ge $text.Length) { $valid = $false; break }
                    
                    $nextCh = $text[$nextIdx]
                    $nextCp = [int]$nextCh
                    
                    if ($reverseMap.ContainsKey($nextCp)) {
                        $nextByte = $reverseMap[$nextCp]
                        if ($nextByte -ge 0x80 -and $nextByte -le 0xBF) {
                            $originalBytes.Add([byte]$nextByte)
                            $charsConsumed++
                        } else {
                            $valid = $false; break
                        }
                    } else {
                        $valid = $false; break
                    }
                }
                
                if ($valid -and $originalBytes.Count -eq ($expectedCont + 1)) {
                    # Validate: decoded char should be non-ASCII and make sense
                    try {
                        $decoded = $utf8.GetString($originalBytes.ToArray())
                        $decodedCp = [int][char]$decoded[0]
                        
                        # Only replace if decoded to a single char above U+007F
                        # and the first byte was above U+00BF (would be a real mojibake start)
                        if ($decoded.Length -ge 1 -and $decodedCp -ge 0x80 -and $cp -ge 0xC0) {
                            [void]$result.Append($decoded)
                            $i += $charsConsumed
                            $fixes++
                            continue
                        }
                    } catch {}
                }
            }
        }
        
        [void]$result.Append($ch)
        $i++
    }
    
    return @{ Text = $result.ToString(); Fixes = $fixes }
}

# Process all Dart files
$dartFiles = Get-ChildItem -Path 'd:\TulasiHotels\lib' -Filter '*.dart' -Recurse
$totalFixed = 0
$fixedFiles = @()

foreach ($file in $dartFiles) {
    $content = [System.IO.File]::ReadAllText($file.FullName, $utf8)
    $fixResult = Fix-Mojibake $content
    
    if ($fixResult.Fixes -gt 0) {
        [System.IO.File]::WriteAllText($file.FullName, $fixResult.Text, (New-Object System.Text.UTF8Encoding $false))
        $totalFixed++
        $fixedFiles += "$($file.Name) ($($fixResult.Fixes) fixes)"
    }
}

Write-Output "Fixed $totalFixed files"
Write-Output "---"
foreach ($f in $fixedFiles) { Write-Output $f }

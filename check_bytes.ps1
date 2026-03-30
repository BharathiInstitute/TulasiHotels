# Check bytes in update_banner.dart around 'available' keyword
$f = 'd:\TulasiHotels\lib\shared\widgets\update_banner.dart'
$bytes = [System.IO.File]::ReadAllBytes($f)
$text = [System.Text.Encoding]::ASCII.GetString($bytes)
$idx = $text.IndexOf('available ')
if ($idx -ge 0) {
    $start = $idx + 10
    $hex = ($bytes[$start..($start+15)] | ForEach-Object { $_.ToString("X2") }) -join " "
    Write-Output "After 'available ': $hex"
}

# Also check offline_banner
$f2 = 'd:\TulasiHotels\lib\shared\widgets\offline_banner.dart'
$bytes2 = [System.IO.File]::ReadAllBytes($f2)
$text2 = [System.Text.Encoding]::ASCII.GetString($bytes2)
$idx2 = $text2.IndexOf('offline ')
if ($idx2 -ge 0) {
    $start2 = $idx2 + 8
    $hex2 = ($bytes2[$start2..($start2+15)] | ForEach-Object { $_.ToString("X2") }) -join " "
    Write-Output "After 'offline ': $hex2"
}

# Check products_web_screen category fallback
$f3 = 'd:\TulasiHotels\lib\features\products\screens\products_web_screen.dart'
$bytes3 = [System.IO.File]::ReadAllBytes($f3)
$text3 = [System.Text.Encoding]::ASCII.GetString($bytes3)
$idx3 = $text3.IndexOf("?? '")
if ($idx3 -ge 0) {
    $start3 = $idx3 + 4
    $hex3 = ($bytes3[$start3..($start3+10)] | ForEach-Object { $_.ToString("X2") }) -join " "
    Write-Output "Category fallback bytes: $hex3"
}

# Count remaining double-encoded patterns
$dartFiles = Get-ChildItem -Path 'd:\TulasiHotels\lib' -Filter '*.dart' -Recurse
$remaining = 0
foreach ($file in $dartFiles) {
    $b = [System.IO.File]::ReadAllBytes($file.FullName)
    for ($i = 0; $i -lt $b.Length - 3; $i++) {
        if ($b[$i] -eq 0xC3 -and $b[$i+1] -ge 0xA0 -and $b[$i+1] -le 0xAF -and $b[$i+2] -eq 0xC2) {
            $remaining++
            break
        }
    }
}
Write-Output "Files still with C3 A0+ C2: $remaining"

# Also check for the specific byte pattern of the display-corrupted chars
# The 'â€"' when viewed in read tool could mean the file has actual bytes E2 80 94 (correct em-dash)
# OR it could have some other encoding issue
$emDashCount = 0
foreach ($file in $dartFiles) {
    $b = [System.IO.File]::ReadAllBytes($file.FullName)
    for ($i = 0; $i -lt $b.Length - 2; $i++) {
        if ($b[$i] -eq 0xE2 -and $b[$i+1] -eq 0x80 -and $b[$i+2] -eq 0x94) {
            $emDashCount++
        }
    }
}
Write-Output "Em-dash (E2 80 94) occurrences across all files: $emDashCount"

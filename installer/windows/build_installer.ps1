# Build script for Tulasi Restaurants Windows Installer
# Produces a single EXE installer using Flutter build + Inno Setup
#
# Prerequisites:
#   1. Flutter SDK installed and in PATH
#   2. Inno Setup 6 installed (https://jrsoftware.org/isinfo.php)
#      Default: "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
#
# Usage: .\build_installer.ps1
#        .\build_installer.ps1 -Clean

param(
    [switch]$SkipFlutterBuild,
    [switch]$Clean,
    [string]$InnoSetupPath = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Resolve-Path "$PSScriptRoot\..\.."

function Invoke-CheckedCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code $LASTEXITCODE`: $Command $($Arguments -join ' ')"
    }
}

function Clear-WindowsCMakeCache {
    $WindowsBuildDir = Join-Path $ProjectRoot "build\windows"
    $StaleCMakeItems = @(
        (Join-Path $WindowsBuildDir "x64\CMakeCache.txt"),
        (Join-Path $WindowsBuildDir "x64\CMakeFiles"),
        (Join-Path $WindowsBuildDir "CMakeCache.txt"),
        (Join-Path $WindowsBuildDir "CMakeFiles")
    )

    foreach ($Item in $StaleCMakeItems) {
        if (Test-Path $Item) {
            Remove-Item $Item -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Ensure-NuGet {
    if (Get-Command "nuget.exe" -ErrorAction SilentlyContinue) {
        return
    }

    $NuGetDir = Join-Path $ProjectRoot ".tools\nuget"
    $NuGetPath = Join-Path $NuGetDir "nuget.exe"
    $NuGetUrl = "https://dist.nuget.org/win-x86-commandline/v5.10.0/nuget.exe"
    $ExpectedHash = "852b71cc8c8c2d40d09ea49d321ff56fd2397b9d6ea9f96e532530307bbbafd3"

    if (-not (Test-Path $NuGetPath)) {
        Write-Host "  NuGet not found. Downloading NuGet CLI..." -ForegroundColor Yellow
        if (-not (Test-Path $NuGetDir)) {
            New-Item -ItemType Directory -Path $NuGetDir -Force | Out-Null
        }
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $NuGetUrl -OutFile $NuGetPath -UseBasicParsing
    }

    $ActualHash = (Get-FileHash -Path $NuGetPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($ActualHash -ne $ExpectedHash) {
        throw "NuGet integrity check failed for $NuGetPath"
    }

    $env:Path = "$NuGetDir;$env:Path"
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Tulasi Restaurants - Windows Installer Build" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Verify Inno Setup is installed, download if missing
if (-not (Test-Path $InnoSetupPath)) {
    Write-Host "Inno Setup not found. Downloading and installing..." -ForegroundColor Yellow
    $InnoInstallerUrl = "https://jrsoftware.org/download.php/is.exe"
    $InnoInstallerPath = Join-Path $env:TEMP "innosetup_installer.exe"
    
    Write-Host "  Downloading Inno Setup 6..." -ForegroundColor Yellow
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $InnoInstallerUrl -OutFile $InnoInstallerPath -UseBasicParsing
    
    Write-Host "  Installing Inno Setup 6 (silent)..." -ForegroundColor Yellow
    Start-Process -FilePath $InnoInstallerPath -ArgumentList "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART" -Wait
    Remove-Item $InnoInstallerPath -Force -ErrorAction SilentlyContinue
    
    if (-not (Test-Path $InnoSetupPath)) {
        Write-Host "ERROR: Inno Setup installation failed." -ForegroundColor Red
        Write-Host "Please install manually from: https://jrsoftware.org/isdl.php" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "  Inno Setup installed successfully." -ForegroundColor Green
}

# Step 2: Build Flutter Windows app
if (-not $SkipFlutterBuild) {
    Write-Host "[1/3] Building Flutter Windows release..." -ForegroundColor Green
    Push-Location $ProjectRoot
    try {
        if ($Clean) {
            Invoke-CheckedCommand "flutter" "clean"
        }
        Clear-WindowsCMakeCache
        Invoke-CheckedCommand "flutter" "pub" "get"
        Ensure-NuGet
        Invoke-CheckedCommand "flutter" "build" "windows" "--release"
    }
    finally {
        Pop-Location
    }
    Write-Host "  Flutter build complete." -ForegroundColor Green
}
else {
    Write-Host "[1/3] Skipping Flutter build (using existing build)." -ForegroundColor Yellow
}

# Step 3: Verify build output exists
$BuildOutput = Join-Path $ProjectRoot "build\windows\x64\runner\Release\tulasihotels.exe"
if (-not (Test-Path $BuildOutput)) {
    Write-Host "ERROR: Flutter build output not found at:" -ForegroundColor Red
    Write-Host "  $BuildOutput" -ForegroundColor Red
    Write-Host "Run without -SkipFlutterBuild to build first." -ForegroundColor Yellow
    exit 1
}

# Step 4: Create output directory
$InstallerOutputDir = Join-Path $ProjectRoot "build\installer"
if (-not (Test-Path $InstallerOutputDir)) {
    New-Item -ItemType Directory -Path $InstallerOutputDir -Force | Out-Null
}

# Step 5: Run Inno Setup compiler
Write-Host "[2/3] Compiling installer with Inno Setup..." -ForegroundColor Green
$IssFile = Join-Path $PSScriptRoot "TulasiRestaurants_Installer.iss"
& $InnoSetupPath $IssFile

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Inno Setup compilation failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit 1
}

# Step 6: Done
$InstallerExe = Join-Path $InstallerOutputDir "TulasiRestaurants_Setup.exe"
Write-Host "[3/3] Installer built successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Output: $InstallerExe" -ForegroundColor White
Write-Host "  Size: $([math]::Round((Get-Item $InstallerExe).Length / 1MB, 1)) MB" -ForegroundColor White
Write-Host "============================================" -ForegroundColor Cyan

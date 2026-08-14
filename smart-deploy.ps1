# Smart Deploy Agent v5.0 - Tulasi Hotels
# Asks smart questions first, then runs everything automatically
# 
# Usage: .\smart-deploy.ps1
#        .\smart-deploy.ps1 -WebsiteOnly                  # Deploy marketing website only (no Flutter build)
#        .\smart-deploy.ps1 -PublishExisting              # Publish current APK + EXE and static download page
#        .\smart-deploy.ps1 -RefreshCiApps                 # Build Android + Windows in CI and download both artifacts
#        .\smart-deploy.ps1 -Rollback                    # Rollback all platforms
#        .\smart-deploy.ps1 -Rollback -RollbackTarget web  # Rollback web only
#        .\smart-deploy.ps1 -DryRun                      # Preview without deploying
#        .\smart-deploy.ps1 -SetupMonitoring             # One-time GCP monitoring setup

param(
    [switch]$Rollback,
    [switch]$DryRun,
    [switch]$SetupMonitoring,
    [switch]$WebsiteOnly,
    [switch]$PublishExisting,
    [switch]$RefreshCiApps,
    [string]$RollbackTarget = ""   # web, windows, android, or blank for all
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
if (-not $root) { $root = Get-Location }

# --- Deployment URLs ---
$websiteUrl = "https://restaurants.tulasierp.com/"
$appUrl = "https://login1-aa21c.web.app/app/"

function Test-CommandAvailable {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Assert-RequiredTools {
    param(
        [bool]$RequireFlutter,
        [bool]$RequireFirebase,
        [bool]$RequireGit
    )

    if ($RequireFlutter -and -not (Test-CommandAvailable "flutter")) {
        Write-Fail "flutter CLI not found. Install Flutter SDK and ensure it is on PATH."
        exit 1
    }

    if ($RequireFirebase -and -not (Test-CommandAvailable "firebase")) {
        Write-Fail "Firebase CLI not found. Install it with 'npm install -g firebase-tools'."
        exit 1
    }

    if ($RequireGit -and -not (Test-CommandAvailable "git")) {
        Write-Fail "git CLI not found. Install git and ensure it is on PATH."
        exit 1
    }
}

# --- Ensure JAVA_HOME and ANDROID_HOME are set ---
if (-not $env:JAVA_HOME) {
    $javaPath = "C:\Program Files\Microsoft\jdk-17.0.18.8-hotspot"
    if (Test-Path $javaPath) { $env:JAVA_HOME = $javaPath }
}
if (-not $env:ANDROID_HOME) {
    $androidPath = "$env:LOCALAPPDATA\Android\Sdk"
    if (Test-Path $androidPath) { $env:ANDROID_HOME = $androidPath; $env:ANDROID_SDK_ROOT = $androidPath }
}

# --- Colors and Helpers ---
function Write-Step { param($msg) Write-Host "`n[STEP] $msg" -ForegroundColor Cyan }
function Write-Ok { param($msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Fail { param($msg) Write-Host "  [FAIL] $msg" -ForegroundColor Red }
function Write-Warn { param($msg) Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Info { param($msg) Write-Host "  [INFO] $msg" -ForegroundColor Gray }

function Pick {
    param([string]$Question, [string[]]$Options)
    Write-Host ""
    Write-Host "  $Question" -ForegroundColor White
    for ($i = 0; $i -lt $Options.Length; $i++) {
        Write-Host "    [$($i+1)] $($Options[$i])" -ForegroundColor Yellow
    }
    do {
        $choice = Read-Host "  > Pick"
        $num = [int]$choice
    } while ($num -lt 1 -or $num -gt $Options.Length)
    return $num
}

function Write-DeployLog {
    param([string]$Entry)
    $logPath = Join-Path $root "deploy-history.log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logPath -Value "[$timestamp] $Entry" -Encoding UTF8
}

function Invoke-WithRetry {
    param([string]$StepName, [scriptblock]$Command, [bool]$CleanOnFail = $true)
    $ErrorActionPreference = "Continue"
    & $Command
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = "Stop"
    if ($exitCode -eq 0) { return $true }

    Write-Warn "$StepName failed (exit code $exitCode). Auto-fixing..."
    Write-DeployLog "RETRY | $StepName failed, attempting auto-fix"
    if ($CleanOnFail) {
        Write-Info "Running flutter clean..."
        $ErrorActionPreference = "Continue"
        flutter clean 2>&1 | Out-Null
        Write-Info "Running flutter pub get..."
        flutter pub get 2>&1 | Out-Null
        $ErrorActionPreference = "Stop"
    }
    Start-Sleep -Seconds 2
    Write-Info "Retrying $StepName..."
    $ErrorActionPreference = "Continue"
    & $Command
    $exitCode2 = $LASTEXITCODE
    $ErrorActionPreference = "Stop"
    if ($exitCode2 -eq 0) {
        Write-Ok "$StepName passed on retry!"
        Write-DeployLog "RETRY | $StepName passed on retry"
        return $true
    }
    Write-Fail "$StepName failed again after retry (exit code $exitCode2)!"
    Write-DeployLog "RETRY | $StepName failed after retry"
    return $false
}

# --- Step-tracking for granular resume ---
$script:completedSteps = @()

function Test-StepDone {
    param([string]$StepName)
    return $script:completedSteps -contains $StepName
}

function Complete-Step {
    param([string]$StepName)
    if ($script:completedSteps -notcontains $StepName) {
        $script:completedSteps += $StepName
    }
    # Persist progress to state file
    Save-Progress
}

function Save-Progress {
    if (-not (Test-Path variable:script:currentState)) { return }
    $script:currentState.completedSteps = $script:completedSteps
    $stateJson = $script:currentState | ConvertTo-Json -Depth 3
    [System.IO.File]::WriteAllText($statePath, $stateJson, [System.Text.UTF8Encoding]::new($false))
}

# ===========================================================
#   --RefreshCiApps: CI build and download, no web deploy
# ===========================================================
if ($RefreshCiApps) {
    if (-not (Test-CommandAvailable "gh")) { Write-Fail "GitHub CLI is required. Install and authenticate with 'gh auth login'."; exit 1 }

    $branch = (git branch --show-current).Trim()
    if ([string]::IsNullOrWhiteSpace($branch)) { $branch = "main" }
    Write-Step "Starting Android + Windows CI build on $branch (web deployment is skipped)..."
    gh workflow run loop2-deploy.yml --ref $branch --field target=apps
    if ($LASTEXITCODE -ne 0) { Write-Fail "Could not start the CI workflow"; exit 1 }

    $runId = (gh run list --workflow loop2-deploy.yml --branch $branch --event workflow_dispatch --limit 1 --json databaseId --jq '.[0].databaseId').Trim()
    if ([string]::IsNullOrWhiteSpace($runId)) {
        Write-Fail "CI workflow started, but its run ID was not available yet. Open GitHub Actions and run this command again after it appears."
        exit 1
    }

    Write-Step "Waiting for CI run $runId..."
    gh run watch $runId --exit-status
    if ($LASTEXITCODE -ne 0) { Write-Fail "CI build failed. Open GitHub Actions run $runId for details."; exit 1 }

    $apkOutputDir = Join-Path $root "build\app\outputs\flutter-apk"
    $windowsOutputDir = Join-Path $root "build\installer"
    New-Item -ItemType Directory -Path $apkOutputDir -Force | Out-Null
    New-Item -ItemType Directory -Path $windowsOutputDir -Force | Out-Null
    gh run download $runId --name release-apk --dir $apkOutputDir
    if ($LASTEXITCODE -ne 0) { Write-Fail "Could not download the Android CI artifact"; exit 1 }
    gh run download $runId --name release-windows-installer --dir $windowsOutputDir
    if ($LASTEXITCODE -ne 0) { Write-Fail "Could not download the Windows CI artifact"; exit 1 }

    Write-Ok "CI artifacts downloaded without deploying web:"
    Write-Info "  Android: $(Join-Path $apkOutputDir 'app-release.apk')"
    Write-Info "  Windows: $(Join-Path $windowsOutputDir 'TulasiRestaurants_Setup.exe')"
    exit 0
}

# ===========================================================
#   --PublishExisting: Publish current APK + EXE, no rebuild
# ===========================================================
if ($PublishExisting) {
    $pubspecPath = Join-Path $root "pubspec.yaml"
    $pubspecContent = Get-Content $pubspecPath -Raw
    if ($pubspecContent -notmatch 'version:\s*(\d+\.\d+\.\d+)\+(\d+)') {
        Write-Fail "Could not read version from pubspec.yaml"
        exit 1
    }

    $releaseVersion = $matches[1]
    $releaseBuild = [int]$matches[2]
    $apkPath = Join-Path $root "build\app\outputs\flutter-apk\app-release.apk"
    $exePath = Join-Path $root "build\installer\TulasiRestaurants_Setup.exe"
    $androidVersionPath = Join-Path $root "installer\android-version.json"
    $windowsVersionPath = Join-Path $root "installer\version.json"
    $downloadPage = Join-Path $root "website\src\pages\download.html"

    if (-not (Test-Path $apkPath)) { Write-Fail "APK not found: $apkPath"; exit 1 }
    if (-not (Test-Path $exePath)) { Write-Fail "Windows installer not found: $exePath"; exit 1 }
    if (-not (Test-CommandAvailable "gsutil")) { Write-Fail "gsutil is required to publish release files"; exit 1 }
    if (-not (Test-CommandAvailable "firebase")) { Write-Fail "firebase CLI is required to publish the download page"; exit 1 }

    $aaptPath = Get-ChildItem "$env:ANDROID_HOME\build-tools\*\aapt.exe" -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending |
        Select-Object -First 1 -ExpandProperty FullName
    if (-not $aaptPath) { Write-Fail "Android SDK aapt.exe is required to validate the APK version"; exit 1 }
    $apkBadging = (& $aaptPath dump badging $apkPath) -join "`n"
    if ($apkBadging -notmatch "versionCode='(\d+)' versionName='([^']+)'" ) {
        Write-Fail "Could not read the APK version metadata"
        exit 1
    }
    $apkBuild = [int]$matches[1]
    $apkVersion = $matches[2]
    if ($apkVersion -ne $releaseVersion -or $apkBuild -ne $releaseBuild) {
        Write-Fail "APK is v$apkVersion+$apkBuild, but pubspec.yaml is v$releaseVersion+$releaseBuild. Build or download the matching CI artifact before publishing."
        exit 1
    }

    $apkName = "TulasiRestaurants_v$releaseVersion.apk"
    $exeName = "TulasiRestaurants_Setup_v$releaseVersion.exe"
    $apkDownloadUrl = "https://firebasestorage.googleapis.com/v0/b/login1-aa21c.firebasestorage.app/o/downloads%2Fandroid%2F$apkName`?alt=media"
    $exeDownloadUrl = "https://firebasestorage.googleapis.com/v0/b/login1-aa21c.firebasestorage.app/o/downloads%2Fwindows%2F$exeName`?alt=media"
    $androidStoragePath = "gs://login1-aa21c.firebasestorage.app/downloads/android"
    $windowsStoragePath = "gs://login1-aa21c.firebasestorage.app/downloads/windows"
    $changelog = "Bug fixes and improvements"

    Write-Step "Publishing existing Android and Windows release v$releaseVersion+$releaseBuild..."

    $androidVersionJson = @{
        version = $releaseVersion; buildNumber = $releaseBuild; downloadUrl = $apkDownloadUrl
        changelog = $changelog; forceUpdate = $false
    } | ConvertTo-Json -Depth 3
    [System.IO.File]::WriteAllText($androidVersionPath, $androidVersionJson, [System.Text.UTF8Encoding]::new($false))

    $windowsVersionJson = @{
        version = $releaseVersion; buildNumber = $releaseBuild; exeDownloadUrl = $exeDownloadUrl
        storeUrl = "https://apps.microsoft.com/detail/tulasi-stores"; changelog = $changelog; forceUpdate = $false
    } | ConvertTo-Json -Depth 3
    [System.IO.File]::WriteAllText($windowsVersionPath, $windowsVersionJson, [System.Text.UTF8Encoding]::new($false))

    $pageContent = Get-Content $downloadPage -Raw
    $pageContent = $pageContent -replace '(id="android-apk-btn"[^>]*href=")[^"]*(")', "`${1}$apkDownloadUrl`${2}"
    $pageContent = $pageContent -replace 'download="TulasiRestaurants(?:_v[\d.]+)?\.apk"', "download=`"$apkName`""
    $pageContent = $pageContent -replace '(<strong>Version:</strong> v)\d+\.\d+\.\d+ \(Build \d+\)', "`${1}$releaseVersion (Build $releaseBuild)"
    $pageContent = $pageContent -replace '(id="windows-exe-btn"[^>]*href=")[^"]*(")', "`${1}$exeDownloadUrl`${2}"
    $pageContent = $pageContent -replace 'download="TulasiRestaurants_Setup(?:_v[\d.]+)?\.exe"', "download=`"$exeName`""
    [System.IO.File]::WriteAllText($downloadPage, $pageContent, [System.Text.UTF8Encoding]::new($false))

    $ErrorActionPreference = "Continue"
    gsutil -h "Cache-Control:no-cache,max-age=0" cp $androidVersionPath "$androidStoragePath/version.json"
    gsutil -h "Content-Type:application/vnd.android.package-archive" -h "Cache-Control:no-cache,max-age=0" cp $apkPath "$androidStoragePath/TulasiRestaurants.apk"
    gsutil -h "Content-Type:application/vnd.android.package-archive" -h "Cache-Control:no-cache,max-age=0" cp $apkPath "$androidStoragePath/$apkName"
    gsutil -h "Cache-Control:no-cache,max-age=0" cp $windowsVersionPath "$windowsStoragePath/version.json"
    gsutil -h "Content-Type:application/octet-stream" -h "Cache-Control:no-cache,max-age=0" cp $exePath "$windowsStoragePath/TulasiRestaurants_Setup.exe"
    gsutil -h "Content-Type:application/octet-stream" -h "Cache-Control:no-cache,max-age=0" cp $exePath "$windowsStoragePath/$exeName"
    $uploadExit = $LASTEXITCODE
    $ErrorActionPreference = "Stop"
    if ($uploadExit -ne 0) { Write-Fail "Firebase Storage upload failed"; exit 1 }

    Write-Step "Deploying the updated download page without rebuilding Flutter web..."
    $distDir = Join-Path $root "dist"
    $websiteDir = Join-Path $root "website"
    $appDir = Join-Path $distDir "app"
    $appBackup = $null
    if (Test-Path $appDir) {
        $appBackup = Join-Path $root "deploy-backups\app_temp_$((Get-Date -Format 'yyyyMMdd_HHmmss'))"
        New-Item -ItemType Directory -Path $appBackup -Force | Out-Null
        Copy-Item -Path "$appDir\*" -Destination $appBackup -Recurse -Force
    }
    if (Test-Path $distDir) { Remove-Item $distDir -Recurse -Force }
    New-Item -ItemType Directory -Path $distDir -Force | Out-Null
    Copy-Item -Path "$websiteDir\*" -Destination $distDir -Recurse -Force
    if ($appBackup) {
        New-Item -ItemType Directory -Path $appDir -Force | Out-Null
        Copy-Item -Path "$appBackup\*" -Destination $appDir -Recurse -Force
        Remove-Item $appBackup -Recurse -Force
    }
    $ErrorActionPreference = "Continue"
    firebase deploy --only hosting
    $hostingExit = $LASTEXITCODE
    $ErrorActionPreference = "Stop"
    if ($hostingExit -ne 0) { Write-Fail "Firebase Hosting deploy failed"; exit 1 }

    Write-Ok "Published Android and Windows v$releaseVersion+$releaseBuild without rebuilding Flutter web"
    exit 0
}

# ===========================================================
#   --WebsiteOnly: Quick website deploy (no Flutter build)
# ===========================================================
if ($WebsiteOnly) {
    Write-Host ""
    Write-Host "========================================================" -ForegroundColor Cyan
    Write-Host "  Website-Only Deploy (Marketing Site)" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan

    $distDir = Join-Path $root "dist"
    $websiteDir = Join-Path $root "website"

    if (-not (Test-Path $websiteDir)) {
        Write-Fail "website/ directory not found!"
        exit 1
    }

    # Backup existing app/ if present
    $appBackup = $null
    $appDir = Join-Path $distDir "app"
    if (Test-Path $appDir) {
        Write-Step "Preserving existing Flutter app (dist/app/)..."
        $appBackup = Join-Path $root "deploy-backups\app_temp_$((Get-Date -Format 'yyyyMMdd_HHmmss'))"
        New-Item -ItemType Directory -Path $appBackup -Force | Out-Null
        Copy-Item -Path "$appDir\*" -Destination $appBackup -Recurse -Force
        Write-Ok "Flutter app backed up"
    }

    # Copy website to dist
    Write-Step "Copying website/ to dist/..."
    if (Test-Path $distDir) { Remove-Item $distDir -Recurse -Force }
    New-Item -ItemType Directory -Path $distDir -Force | Out-Null
    Copy-Item -Path "$websiteDir\*" -Destination $distDir -Recurse -Force
    Write-Ok "Website copied to dist/"

    # Restore app/
    if ($appBackup) {
        $appDirNew = Join-Path $distDir "app"
        New-Item -ItemType Directory -Path $appDirNew -Force | Out-Null
        Copy-Item -Path "$appBackup\*" -Destination $appDirNew -Recurse -Force
        Remove-Item $appBackup -Recurse -Force
        Write-Ok "Flutter app restored to dist/app/"
    } else {
        Write-Warn "No existing Flutter app found in dist/app/ -- website will deploy without /app/ route"
    }

    # Create serve.json
    $serveJson = '{"rewrites":[{"source":"/app/**","destination":"/app/index.html"}],"headers":[{"source":"**/*","headers":[{"key":"Cache-Control","value":"no-cache"}]}]}'
    [System.IO.File]::WriteAllText((Join-Path $distDir "serve.json"), $serveJson, [System.Text.UTF8Encoding]::new($false))

    if ($DryRun) {
        Write-Host ""
        Write-Ok "[DRY-RUN] Would deploy dist/ to Firebase Hosting"
        Write-DeployLog "DRY-RUN | Website-only preview"
        exit 0
    }

    # Deploy
    Write-Step "Deploying to Firebase Hosting..."
    $ErrorActionPreference = "Continue"
    firebase deploy --only hosting
    $fbExit = $LASTEXITCODE
    $ErrorActionPreference = "Stop"

    if ($fbExit -eq 0) {
        Write-Ok "Website deployed to Firebase Hosting!"
        Write-DeployLog "WEBSITE DEPLOY | Marketing site updated"

        # Health check
        Write-Step "Health check..."
        Start-Sleep -Seconds 5
        $healthUrls = @(
            $websiteUrl,
            $appUrl
        )
        foreach ($url in $healthUrls) {
            try {
                $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
                if ($response.StatusCode -eq 200) { Write-Ok "$url -> HTTP 200" }
                else { Write-Warn "$url -> HTTP $($response.StatusCode)" }
            }
            catch { Write-Warn "$url -> Could not reach" }
        }

        # Git commit
        Write-Step "Git commit + push..."
        $ErrorActionPreference = "Continue"
        git add -A 2>&1 | Out-Null
        git commit -m "website: update marketing site" 2>&1 | Out-Null
        git push 2>&1 | Out-Null
        Write-Ok "Pushed to remote"
        $ErrorActionPreference = "Stop"
        Write-DeployLog "GIT | Website update pushed"

        Write-Host ""
        Write-Host "========================================================" -ForegroundColor Green
        Write-Host "  Website Deploy Complete!" -ForegroundColor Green
        Write-Host "========================================================" -ForegroundColor Green
        Write-Host "  Website: $websiteUrl" -ForegroundColor White
        Write-Host "  App:     $appUrl" -ForegroundColor White
        Write-Host "  Log:     deploy-history.log" -ForegroundColor Gray
        Write-Host ""
        Write-DeployLog "WEBSITE DEPLOY COMPLETE"
        Write-DeployLog "------------------------------------------------"
    } else {
        Write-Fail "Firebase deploy failed!"
        Write-DeployLog "WEBSITE DEPLOY FAILED"
        exit 1
    }
    exit 0
}

# ===========================================================
#   --setup-monitoring: One-time GCP budget + uptime setup
# ===========================================================
if ($SetupMonitoring) {
    Write-Host ""
    Write-Host "========================================================" -ForegroundColor Cyan
    Write-Host "  GCP Monitoring & Budget Setup" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan

    # Check gcloud is available
    $gcloudExists = Get-Command gcloud -ErrorAction SilentlyContinue
    if (-not $gcloudExists) {
        Write-Fail "gcloud CLI not found. Install: https://cloud.google.com/sdk/docs/install"
        exit 1
    }

    $projectId = (gcloud config get-value project 2>$null)
    if (-not $projectId) { $projectId = "login1-aa21c" }
    Write-Info "Project: $projectId"

    # 1. Enable required APIs
    Write-Step "Enabling Monitoring & Billing APIs..."
    $ErrorActionPreference = "Continue"
    gcloud services enable monitoring.googleapis.com --project $projectId 2>&1 | Out-Null
    gcloud services enable cloudbilling.googleapis.com --project $projectId 2>&1 | Out-Null
    gcloud services enable billingbudgets.googleapis.com --project $projectId 2>&1 | Out-Null
    $ErrorActionPreference = "Stop"
    Write-Ok "APIs enabled"

    # 2. Create uptime check for web app
    Write-Step "Creating uptime check for web app..."
    $ErrorActionPreference = "Continue"
    gcloud monitoring uptime create "Tulasi Hotels Web App" `
        --resource-type=uptime-url `
        --resource-labels="host=login1-aa21c.web.app,project_id=$projectId" `
        --protocol=https `
        --path="/" `
        --period=5 `
        --project $projectId 2>&1
    $ErrorActionPreference = "Stop"
    Write-Ok "Uptime check created (checks every 5 min)"

    # 3. Create uptime check for Flutter app
    Write-Step "Creating uptime check for Flutter web app..."
    $ErrorActionPreference = "Continue"
    gcloud monitoring uptime create "Tulasi Hotels Flutter App" `
        --resource-type=uptime-url `
        --resource-labels="host=login1-aa21c.web.app,project_id=$projectId" `
        --protocol=https `
        --path="/app/" `
        --period=5 `
        --project $projectId 2>&1
    $ErrorActionPreference = "Stop"
    Write-Ok "App uptime check created"

    # 4. GCS backup lifecycle (auto-delete backups > 30 days)
    Write-Step "Setting backup retention policy (30 days)..."
    $backupBucket = "$projectId-firestore-backups"
    $lifecycleConfig = @"
{
  "rule": [
    {
      "action": { "type": "Delete" },
      "condition": { "age": 30 }
    }
  ]
}
"@
    $lifecycleFile = Join-Path $root "lifecycle.json"
    [System.IO.File]::WriteAllText($lifecycleFile, $lifecycleConfig, [System.Text.UTF8Encoding]::new($false))

    $ErrorActionPreference = "Continue"
    gsutil lifecycle set $lifecycleFile "gs://$backupBucket" 2>&1
    $gsExit = $LASTEXITCODE
    $ErrorActionPreference = "Stop"
    Remove-Item $lifecycleFile -Force -ErrorAction SilentlyContinue

    if ($gsExit -eq 0) {
        Write-Ok "Backup retention: 30 days (auto-delete older)"
    } else {
        Write-Warn "Could not set lifecycle. Run manually:"
        Write-Info "  gsutil lifecycle set lifecycle.json gs://$backupBucket"
    }

    # 5. Budget alerts
    Write-Step "Budget alert setup instructions..."
    Write-Host ""
    Write-Host "  +-------------------------------------------------+" -ForegroundColor Yellow
    Write-Host "  |  GCP Budget Alerts (manual -- requires billing    |" -ForegroundColor Yellow
    Write-Host "  |  admin access via console):                      |" -ForegroundColor Yellow
    Write-Host "  |                                                  |" -ForegroundColor Yellow
    Write-Host "  |  1. Go to: console.cloud.google.com/billing     |" -ForegroundColor White
    Write-Host "  |  2. Select your billing account                  |" -ForegroundColor White
    Write-Host "  |  3. Budgets & alerts > CREATE BUDGET             |" -ForegroundColor White
    Write-Host "  |  4. Set thresholds at: `$50, `$100, `$200         |" -ForegroundColor White
    Write-Host "  |  5. Add email recipients for alerts              |" -ForegroundColor White
    Write-Host "  |                                                  |" -ForegroundColor Yellow
    Write-Host "  |  Recommended monthly budget: `$100 for 10K users |" -ForegroundColor Cyan
    Write-Host "  +-------------------------------------------------+" -ForegroundColor Yellow
    Write-Host ""

    Write-Host ""
    Write-Host "========================================================" -ForegroundColor Green
    Write-Host "  Monitoring setup complete!" -ForegroundColor Green
    Write-Host "========================================================" -ForegroundColor Green
    Write-Host "  - Uptime checks: web + app (every 5 min)" -ForegroundColor Green
    Write-Host "  - Backup retention: 30 days auto-delete" -ForegroundColor Green
    Write-Host "  - Budget alerts: follow instructions above" -ForegroundColor Yellow
    Write-Host ""
    Write-DeployLog "MONITORING | Setup complete -- uptime checks + backup retention"
    exit 0
}

# ===========================================================
#   --rollback: Revert to previous deployment
# ===========================================================
if ($Rollback) {
    Write-Host ""
    Write-Host "========================================================" -ForegroundColor Yellow
    Write-Host "  ROLLBACK MODE" -ForegroundColor Yellow
    Write-Host "========================================================" -ForegroundColor Yellow

    $backupDir = Join-Path $root "deploy-backups"
    $targets = @()

    if ($RollbackTarget -eq "" -or $RollbackTarget -eq "all") {
        $targets = @("web", "windows", "android")
    } else {
        $targets = @($RollbackTarget.ToLower())
    }

    $rollbackPerformed = $false

    # --- Rollback Web ---
    if ($targets -contains "web") {
        $distBackups = Get-ChildItem $backupDir -Directory -Filter "dist_*" -ErrorAction SilentlyContinue | Sort-Object Name -Descending
        if ($distBackups.Count -gt 0) {
            $latestBackup = $distBackups[0]
            Write-Step "Rolling back Web from backup: $($latestBackup.Name)"

            if ($DryRun) {
                Write-Info "[DRY-RUN] Would restore $($latestBackup.FullName) to dist/ and deploy"
            } else {
                $distDir = Join-Path $root "dist"
                if (Test-Path $distDir) { Remove-Item $distDir -Recurse -Force }
                New-Item -ItemType Directory -Path $distDir -Force | Out-Null
                Copy-Item -Path "$($latestBackup.FullName)\*" -Destination $distDir -Recurse -Force
                Write-Ok "Restored dist/ from backup"

                Write-Step "Deploying rolled-back web to Firebase Hosting..."
                $ErrorActionPreference = "Continue"
                firebase deploy --only hosting
                $fbExit = $LASTEXITCODE
                $ErrorActionPreference = "Stop"

                if ($fbExit -eq 0) {
                    Write-Ok "Web rollback deployed!"
                    Write-DeployLog "ROLLBACK | Web restored from $($latestBackup.Name)"
                    $rollbackPerformed = $true
                } else {
                    Write-Fail "Firebase hosting deploy failed during rollback!"
                }
            }
        } else {
            Write-Warn "No web backup found in deploy-backups/"
        }
    }

    # --- Rollback Windows ---
    if ($targets -contains "windows") {
        $winBackups = Get-ChildItem $backupDir -File -Filter "version_win_*" -ErrorAction SilentlyContinue | Sort-Object Name -Descending
        if ($winBackups.Count -gt 0) {
            $latestWinBackup = $winBackups[0]
            Write-Step "Rolling back Windows version.json from: $($latestWinBackup.Name)"

            if ($DryRun) {
                Write-Info "[DRY-RUN] Would restore $($latestWinBackup.Name) to installer/version.json and upload"
            } else {
                $winVersionPath = Join-Path $root "installer\version.json"
                Copy-Item $latestWinBackup.FullName $winVersionPath -Force
                Write-Ok "Restored installer/version.json"

                $gsutilExists = Get-Command gsutil -ErrorAction SilentlyContinue
                if ($gsutilExists) {
                    $storagePath = "gs://login1-aa21c.firebasestorage.app/downloads/windows/"
                    gsutil cp $winVersionPath "${storagePath}version.json"
                    gsutil setmeta -h "Cache-Control:no-cache,max-age=0" "${storagePath}version.json"
                    Write-Ok "Windows version.json uploaded to Storage"
                    Write-DeployLog "ROLLBACK | Windows version.json restored from $($latestWinBackup.Name)"
                    $rollbackPerformed = $true
                } else {
                    Write-Warn "gsutil not found -- upload installer/version.json manually"
                }
            }
        } else {
            Write-Warn "No Windows backup found in deploy-backups/"
        }
    }

    # --- Rollback Android ---
    if ($targets -contains "android") {
        $androidBackups = Get-ChildItem $backupDir -File -Filter "version_android_*" -ErrorAction SilentlyContinue | Sort-Object Name -Descending
        if ($androidBackups.Count -gt 0) {
            $latestAndBackup = $androidBackups[0]
            Write-Step "Rolling back Android version.json from: $($latestAndBackup.Name)"

            if ($DryRun) {
                Write-Info "[DRY-RUN] Would restore $($latestAndBackup.Name) to installer/android-version.json and upload"
            } else {
                $androidVersionPath = Join-Path $root "installer\android-version.json"
                Copy-Item $latestAndBackup.FullName $androidVersionPath -Force
                Write-Ok "Restored installer/android-version.json"

                $gsutilExists = Get-Command gsutil -ErrorAction SilentlyContinue
                if ($gsutilExists) {
                    $storagePath = "gs://login1-aa21c.firebasestorage.app/downloads/android/"
                    gsutil cp $androidVersionPath "${storagePath}version.json"
                    gsutil setmeta -h "Cache-Control:no-cache,max-age=0" "${storagePath}version.json"
                    Write-Ok "Android version.json uploaded to Storage"
                    Write-DeployLog "ROLLBACK | Android version.json restored from $($latestAndBackup.Name)"
                    $rollbackPerformed = $true
                } else {
                    Write-Warn "gsutil not found -- upload installer/android-version.json manually"
                }
            }
        } else {
            Write-Warn "No Android backup found in deploy-backups/"
        }
    }

    if ($DryRun) {
        Write-Host ""
        Write-Ok "[DRY-RUN] Rollback preview complete. No changes made."
    } elseif ($rollbackPerformed) {
        Write-Host ""
        Write-Host "========================================================" -ForegroundColor Green
        Write-Host "  Rollback Complete!" -ForegroundColor Green
        Write-Host "========================================================" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Warn "No rollback was performed."
    }
    exit 0
}

# ===========================================================
#   CHECK FOR RESUME -- skip questions if previous run failed
# ===========================================================
$statePath = Join-Path $root "deploy-state.json"
$resumed = $false

if (Test-Path $statePath) {
    $savedState = Get-Content $statePath -Raw | ConvertFrom-Json
    Write-Host ""
    Write-Host "========================================================" -ForegroundColor Yellow
    Write-Host "  Previous deploy found! (failed or interrupted)" -ForegroundColor Yellow
    Write-Host "========================================================" -ForegroundColor Yellow
    Write-Host "  Type:       $($savedState.typeName)" -ForegroundColor White
    Write-Host "  Version:    $($savedState.newVersion)+$($savedState.newBuild)" -ForegroundColor White
    if ($savedState.platforms) { Write-Host "  Platforms:  $($savedState.platforms)" -ForegroundColor White }
    if ($savedState.winChoiceLabel) { Write-Host "  Windows:    $($savedState.winChoiceLabel)" -ForegroundColor White }
    Write-Host ""
    # Show completed steps if any
    if ($savedState.completedSteps) {
        $doneSteps = @($savedState.completedSteps)
        if ($doneSteps.Count -gt 0) {
            Write-Host "  Completed:  $($doneSteps -join ', ')" -ForegroundColor Green
            Write-Host "  (These steps will be SKIPPED on resume)" -ForegroundColor Gray
        }
    }
    Write-Host ""
    $resumeChoice = Read-Host "  Resume with same settings? (Y/n)"
    if ($resumeChoice -ne 'n' -and $resumeChoice -ne 'N') {
        $resumed = $true
        $updateType = [int]$savedState.updateType
        $skipBuild = [bool]$savedState.skipBuild
        $deployWeb = [bool]$savedState.deployWeb
        $deployWindows = [bool]$savedState.deployWindows
        $deployAndroid = [bool]$savedState.deployAndroid
        $newVersion = $savedState.newVersion
        $newBuild = [int]$savedState.newBuild
        $changelog = $savedState.changelog
        $forceMinVersion = $savedState.forceMinVersion
        $announcementMsg = $savedState.announcementMsg
        $setLatestVersion = [bool]$savedState.setLatestVersion
        $buildMsix = [bool]$savedState.buildMsix
        $buildExe = [bool]$savedState.buildExe
        $winChoiceLabel = $savedState.winChoiceLabel
        $deployWebsiteOnly = [bool]$savedState.deployWebsiteOnly
        # Restore completed steps for granular resume
        if ($savedState.completedSteps) {
            $script:completedSteps = @($savedState.completedSteps)
        }
        # Initialize $script:currentState for Save-Progress
        $script:currentState = @{
            updateType         = $updateType
            typeName           = $savedState.typeName
            skipBuild          = $skipBuild
            deployWeb          = $deployWeb
            deployWindows      = $deployWindows
            deployAndroid      = $deployAndroid
            deployWebsiteOnly  = $deployWebsiteOnly
            newVersion         = $newVersion
            newBuild           = $newBuild
            changelog          = $changelog
            forceMinVersion    = $forceMinVersion
            announcementMsg    = $announcementMsg
            setLatestVersion   = $setLatestVersion
            buildMsix          = $buildMsix
            buildExe           = $buildExe
            winChoiceLabel     = $winChoiceLabel
            completedSteps     = $script:completedSteps
            platforms        = $savedState.platforms
            savedAt          = $savedState.savedAt
        }
        Write-Host ""
        Write-Ok "Resuming deploy with saved settings!"
        if ($script:completedSteps.Count -gt 0) {
            Write-Ok "Will skip: $($script:completedSteps -join ', ')"
        }
        Write-DeployLog "RESUME | Restarting with saved settings (skipping: $($script:completedSteps -join ', '))"
    }
    else {
        # User wants fresh start -- delete old state
        Remove-Item $statePath -Force
        Write-Info "Previous state cleared. Starting fresh."
    }
}

if (-not $resumed) {
    # ===========================================================
    #   PHASE 1: ASK ALL QUESTIONS UPFRONT
    # ===========================================================
    Write-Host ""
    Write-Host "========================================================" -ForegroundColor Cyan
    Write-Host "  Tulasi Hotels - Smart Deploy Agent v5.0" -ForegroundColor Cyan
    Write-Host "  Answer a few questions, then I do the rest!" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan

    # --- Q1: Update type ---
    $updateType = Pick "Q1: What type of update?" @(
        "Normal      - feature, minor fix",
        "Patch Fix   - bug fix, quick patch",
        "Critical    - FORCE all users to update",
        "Maintenance - block ALL users temporarily",
        "Config Only - Remote Config change, no code"
    )

    $skipBuild = ($updateType -eq 4 -or $updateType -eq 5)
    $deployWeb = $false
    $deployWindows = $false
    $deployAndroid = $false
    $deployWebsiteOnly = $false

    # --- Q2: Platforms ---
    if (-not $skipBuild) {
        $platformChoice = Pick "Q2: What do you want to build/deploy?" @(
            "Website only         (marketing site only)",
            "Build Web & Host     (Flutter web + Firebase Hosting)",
            "Build EXE            (Windows installer only)",
            "Build APK            (Android APK only)",
            "Build Web & Host + EXE",
            "Build Web & Host + APK",
            "Build EXE + APK",
            "Build Web & Host + EXE + APK"
        )
        switch ($platformChoice) {
            1 { $deployWebsiteOnly = $true }
            2 { $deployWeb = $true }
            3 { $deployWindows = $true }
            4 { $deployAndroid = $true }
            5 { $deployWeb = $true; $deployWindows = $true }
            6 { $deployWeb = $true; $deployAndroid = $true }
            7 { $deployWindows = $true; $deployAndroid = $true }
            8 { $deployWeb = $true; $deployWindows = $true; $deployAndroid = $true }
        }
    }

    # --- Parse current version ---
    $pubspecPath = Join-Path $root "pubspec.yaml"
    $pubspecContent = Get-Content $pubspecPath -Raw
    $currentVersion = if ($pubspecContent -match 'version:\s*(\d+\.\d+\.\d+)\+(\d+)') {
        @{ version = $matches[1]; build = [int]$matches[2] }
    }
    else {
        @{ version = "1.0.0"; build = 1 }
    }

    $newVersion = $currentVersion.version
    $newBuild = $currentVersion.build

    # --- Q3: Version bump ---
    if (-not $skipBuild -and -not $deployWebsiteOnly) {
        $parts = $currentVersion.version -split '\.'
        $patchBumped = "$($parts[0]).$($parts[1]).$([int]$parts[2] + 1)"
        $minorBumped = "$($parts[0]).$([int]$parts[1] + 1).0"
        $majorBumped = "$([int]$parts[0] + 1).0.0"
        $buildBumped = $currentVersion.build + 1

        Write-Host ""
        Write-Host "  Current: $($currentVersion.version)+$($currentVersion.build)" -ForegroundColor Gray

        $bumpChoice = Pick "Q3: Version bump?" @(
            "Build only     ($($currentVersion.version)+$buildBumped)",
            "Patch          ($patchBumped+$buildBumped)",
            "Minor          ($minorBumped+$buildBumped)",
            "Major          ($majorBumped+$buildBumped)",
            "Custom         - enter manually"
        )

        $newBuild = $buildBumped
        switch ($bumpChoice) {
            1 { $newVersion = $currentVersion.version }
            2 { $newVersion = $patchBumped }
            3 { $newVersion = $minorBumped }
            4 { $newVersion = $majorBumped }
            5 {
                $newVersion = Read-Host "  Enter version (e.g. 1.2.3)"
                $newBuild = [int](Read-Host "  Enter build number")
            }
        }
    }

    # --- Q4: Changelog ---
    $changelog = ""
    if (-not $skipBuild -and -not $deployWebsiteOnly) {
        Write-Host ""
        Write-Host "  Q4: What changed? (one per line, blank to finish)" -ForegroundColor White
        $lines = @()
        while ($true) {
            $line = Read-Host "  *"
            if ([string]::IsNullOrWhiteSpace($line)) { break }
            $lines += "* $line"
        }
        $changelog = $lines -join "`n"
        if ($changelog -eq "") { $changelog = "Bug fixes and improvements" }
    }

    # --- Q5: Force version (critical only) ---
    $forceMinVersion = ""
    if ($updateType -eq 3) {
        $forceMinVersion = Read-Host "  Q5: Minimum required version to force? (Enter = $newVersion)"
        if ([string]::IsNullOrWhiteSpace($forceMinVersion)) { $forceMinVersion = $newVersion }
    }

    # --- Q5/Q6: Announcement (optional) ---
    $announcementMsg = ""
    $setLatestVersion = $false
    if (-not $skipBuild -and -not $deployWebsiteOnly -and $updateType -le 3) {
        $setLatestVersion = $true

        Write-Host ""
        $announcementInput = Read-Host "  Q5: Announcement for ALL users? (Enter = skip)"
        if (-not [string]::IsNullOrWhiteSpace($announcementInput)) {
            $announcementMsg = $announcementInput
        }
    }

    # --- Q6: Windows installer type (if deploying Windows) ---
    $buildMsix = $false
    $buildExe = $false
    $winChoiceLabel = ""
    if ($deployWindows) {
        Write-Host ""
        Write-Host "  +-----------------------------------------+" -ForegroundColor Cyan
        Write-Host "  |  Q6: Which Windows installer to build?  |" -ForegroundColor Cyan
        Write-Host "  |                                         |" -ForegroundColor Cyan
        Write-Host "  |  [1] Microsoft Store (MSIX only)        |" -ForegroundColor White
        Write-Host "  |  [2] Web Download (EXE only)            |" -ForegroundColor White
        Write-Host "  |  [3] Both (MSIX + EXE)                  |" -ForegroundColor Yellow
        Write-Host "  |                                         |" -ForegroundColor Cyan
        Write-Host "  +-----------------------------------------+" -ForegroundColor Cyan
        $winChoice = Read-Host "  Choose [1/2/3]"
        if ($winChoice -notin @("1", "2", "3")) { $winChoice = "3" }
        $buildMsix = $winChoice -in @("1", "3")
        $buildExe = $winChoice -in @("2", "3")
        $winChoiceLabel = switch ($winChoice) { "1" { "Store (MSIX)" }; "2" { "Web Download (EXE)" }; "3" { "Both (MSIX + EXE)" } }
    }

    $requireFlutter = (-not $skipBuild -and -not $deployWebsiteOnly)
    $requireFirebase = $deployWebsiteOnly -or $deployWeb
    $requireGit = $deployWebsiteOnly -or (-not $skipBuild -and -not $deployWebsiteOnly)
    Assert-RequiredTools -RequireFlutter $requireFlutter -RequireFirebase $requireFirebase -RequireGit $requireGit

    # ===========================================================
    #   CONFIRM - Last chance to cancel
    # ===========================================================
    Write-Host ""
    Write-Host "========================================================" -ForegroundColor Cyan
    Write-Host "  Deploy Plan" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan

    $typeNames = @("", "Normal", "Patch", "Critical", "Maintenance", "Config Only")
    Write-Host "  Type:       $($typeNames[$updateType])" -ForegroundColor White
    if ($deployWebsiteOnly) {
        Write-Host "  Platforms:  Website only (no Flutter build)" -ForegroundColor White
    } elseif (-not $skipBuild) {
        Write-Host "  Version:    $newVersion+$newBuild" -ForegroundColor White
        $platforms = @()
        if ($deployWeb) { $platforms += "Web & Host" }
        if ($deployWindows) { $platforms += "EXE" }
        if ($deployAndroid) { $platforms += "APK" }
        Write-Host "  Platforms:  $($platforms -join ', ')" -ForegroundColor White
        if ($winChoiceLabel) { Write-Host "  Windows:    $winChoiceLabel" -ForegroundColor White }
        if ($changelog) {
            $previewLen = [Math]::Min(60, $changelog.Length)
            Write-Host "  Changelog:  $($changelog.Substring(0, $previewLen))..." -ForegroundColor Gray
        }
    }
    if ($forceMinVersion) { Write-Host "  Force min:  v$forceMinVersion" -ForegroundColor Red }
    if ($announcementMsg) { Write-Host "  Announce:   $announcementMsg" -ForegroundColor Cyan }
    if ($updateType -eq 4) { Write-Host "  Action:     Enable maintenance mode" -ForegroundColor Yellow }
    Write-Host "  Hosting:    https://login1-aa21c.web.app/" -ForegroundColor Gray

    Write-Host ""
    Write-Host "  After confirm, I will automatically:" -ForegroundColor Gray
    if ($deployWebsiteOnly) {
        Write-Host "    > Copy website/ to dist/ (preserve existing app/)" -ForegroundColor Gray
        Write-Host "    > Deploy to Firebase Hosting" -ForegroundColor Gray
        Write-Host "    > Health check website + app URLs" -ForegroundColor Gray
        Write-Host "    > Git commit + push" -ForegroundColor Gray
    } elseif (-not $skipBuild) {
        Write-Host "    > Run tests + analyzer" -ForegroundColor Gray
        Write-Host "    > Bump version in pubspec.yaml" -ForegroundColor Gray
        Write-Host "    > Backup current deployment" -ForegroundColor Gray
        if ($deployWeb) { Write-Host "    > Build Web & Host + health check" -ForegroundColor Gray }
        if ($deployWindows) { Write-Host "    > Build EXE + upload to Storage" -ForegroundColor Gray }
        if ($deployAndroid) { Write-Host "    > Push version changes; GitHub Actions builds, signs, and uploads the APK" -ForegroundColor Gray }
        Write-Host "    > Git commit + tag + push" -ForegroundColor Gray
    }
    Write-Host ""

    $confirm = Read-Host "  Deploy? (y/n)"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Host "`n  Deploy cancelled." -ForegroundColor Yellow
        exit 0
    }

    # Save state for resume on failure
    $pubspecPath = Join-Path $root "pubspec.yaml"
    $typeNames = @("", "Normal", "Patch", "Critical", "Maintenance", "Config Only")
    $script:currentState = @{
        updateType         = $updateType
        typeName           = $typeNames[$updateType]
        skipBuild          = $skipBuild
        deployWeb          = $deployWeb
        deployWindows      = $deployWindows
        deployAndroid      = $deployAndroid
        deployWebsiteOnly  = $deployWebsiteOnly
        newVersion         = $newVersion
        newBuild           = $newBuild
        changelog          = $changelog
        forceMinVersion    = $forceMinVersion
        announcementMsg    = $announcementMsg
        setLatestVersion   = $setLatestVersion
        buildMsix          = $buildMsix
        buildExe           = $buildExe
        winChoiceLabel     = $winChoiceLabel
        completedSteps     = @()
        platforms          = $(if ($deployWebsiteOnly) { 'Website only' } else { (@($(if ($deployWeb) { 'Web & Host' }), $(if ($deployWindows) { 'EXE' }), $(if ($deployAndroid) { 'APK' })) | Where-Object { $_ }) -join ', ' })
        savedAt            = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }
    $stateData = $script:currentState | ConvertTo-Json -Depth 3
    [System.IO.File]::WriteAllText($statePath, $stateData, [System.Text.UTF8Encoding]::new($false))
    Write-Info "Settings saved for resume"

} # end if (-not $resumed)

# ===========================================================
#   PHASE 2: RUN THE DEPLOY
#   On error: script stops. Fix the error, re-run the script.
#   It will resume with same settings automatically.
# ===========================================================
$failed = $false
$typeNames = @("", "Normal", "Patch", "Critical", "Maintenance", "Config Only")
$pubspecPath = Join-Path $root "pubspec.yaml"

Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
if ($resumed) {
    Write-Host "  Resuming deploy... sit back and watch!" -ForegroundColor Green
}
else {
    Write-Host "  Running... sit back and watch!" -ForegroundColor Green
}
Write-Host "========================================================" -ForegroundColor Green

Write-DeployLog "DEPLOY START | Type: $($typeNames[$updateType]) | Version: $newVersion+$newBuild"

# --- Dry-run mode: show plan and exit ---
if ($DryRun) {
    Write-Host ""
    Write-Host "  [DRY-RUN MODE] No changes will be made." -ForegroundColor Yellow
    Write-Host ""
    if (-not $skipBuild) {
        Write-Info "Would update pubspec.yaml to $newVersion+$newBuild"
        Write-Info "Would run: flutter test --reporter compact"
        Write-Info "Would run: flutter analyze"
    }
    if ($deployWebsiteOnly) { Write-Info "Would copy website/ to dist/ + deploy to Firebase Hosting + health check" }
    if ($deployWeb) { Write-Info "Would build Flutter web + copy website + deploy to Firebase Hosting + health check" }
    if ($deployWindows) { Write-Info "Would build Windows + create $winChoiceLabel + upload to Storage" }
    if ($deployAndroid) { Write-Info "Would push version changes; GitHub Actions would build and upload Android" }
    if (-not $skipBuild -and -not $deployWebsiteOnly) { Write-Info "Would git commit + tag v$newVersion+$newBuild + push" }
    if ($forceMinVersion) { Write-Info "Would set Remote Config: min_app_version = $forceMinVersion" }
    if ($announcementMsg) { Write-Info "Would set Remote Config: announcement = $announcementMsg" }
    Write-Host ""
    Write-Ok "[DRY-RUN] Preview complete. Run without --dry-run to execute."
    Write-DeployLog "DRY-RUN | Preview only, no changes made"
    if (Test-Path $statePath) { Remove-Item $statePath -Force }
    exit 0
}

try {
    # <- Catch ALL errors -- nothing can stop us!

    # --- Update pubspec.yaml ---
    if (-not $skipBuild -and -not $deployWebsiteOnly -and -not (Test-StepDone "version_bump")) {
        Write-Step "Updating version to $newVersion+$newBuild"
        $pubspecContent = Get-Content $pubspecPath -Raw
        $pubspecContent = $pubspecContent -replace 'version:\s*\d+\.\d+\.\d+\+\d+', "version: $newVersion+$newBuild"
        [System.IO.File]::WriteAllText($pubspecPath, $pubspecContent, [System.Text.UTF8Encoding]::new($false))
        Write-Ok "pubspec.yaml updated"
        Complete-Step "version_bump"
    }
    elseif (Test-StepDone "version_bump") {
        Write-Info "SKIP: Version already bumped"
    }

    # --- Run Tests ---
    if (-not $skipBuild -and -not $deployWebsiteOnly -and -not $failed -and -not (Test-StepDone "tests")) {
        Write-Step "Running tests..."
        $ErrorActionPreference = "Continue"
        flutter test --concurrency=1 --reporter compact
        $testExit = $LASTEXITCODE
        $ErrorActionPreference = "Stop"
        if ($testExit -ne 0) {
            Write-Fail "Tests failed!"
            $failed = $true
        }
        else {
            Write-Ok "All tests passed"
            Write-DeployLog "TESTS PASSED"
        }
    }
    elseif (Test-StepDone "tests") {
        Write-Info "SKIP: Tests already passed"
    }

    # --- Run Analyzer ---
    if (-not $skipBuild -and -not $deployWebsiteOnly -and -not $failed -and -not (Test-StepDone "analyzer")) {
        Write-Step "Running analyzer..."
        $ErrorActionPreference = "Continue"
        flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings
        $analyzeExit = $LASTEXITCODE
        $ErrorActionPreference = "Stop"
        if ($analyzeExit -ne 0) {
            Write-Fail "Analysis has real errors!"
            $failed = $true
        }
        else {
            Write-Ok "Analysis passed"
            Write-DeployLog "ANALYSIS PASSED"
            Complete-Step "tests"  # Mark tests+analyzer as done together
            Complete-Step "analyzer"
        }
    }
    elseif (Test-StepDone "analyzer") {
        Write-Info "SKIP: Analyzer already passed"
    }

    # --- Backup ---
    $backupDir = Join-Path $root "deploy-backups"
    $backupTimestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"

    if (-not $failed -and $deployWeb) {
        $distDir = Join-Path $root "dist"
        if (Test-Path $distDir) {
            Write-Step "Backing up current web deployment..."
            $backupPath = Join-Path $backupDir "dist_$backupTimestamp"
            New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
            Copy-Item -Path "$distDir\*" -Destination $backupPath -Recurse -Force
            Write-Ok "Backup saved"
            Write-DeployLog "BACKUP | Web"
        }
    }

    if (-not $failed -and $deployWindows) {
        $winVersionPath = Join-Path $root "installer\version.json"
        if (Test-Path $winVersionPath) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            Copy-Item $winVersionPath (Join-Path $backupDir "version_win_$backupTimestamp.json")
        }
    }

    if (-not $failed -and $deployAndroid) {
        $androidVersionPath = Join-Path $root "installer\android-version.json"
        if (Test-Path $androidVersionPath) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            Copy-Item $androidVersionPath (Join-Path $backupDir "version_android_$backupTimestamp.json")
        }
    }

    # --- Build and Deploy: Windows (MSIX + Inno Setup EXE) --- [RUNS FIRST to update download.html before web deploy]
    if (-not $failed -and $deployWindows -and -not (Test-StepDone "windows")) {
        Write-Step "Building Windows -- $winChoiceLabel..."

        # Update MSIX version in pubspec.yaml (MSIX needs x.x.x.0 format)
        $msixVersion = "$newVersion.0"
        $currentPubspec = Get-Content $pubspecPath -Raw
        $currentPubspec = $currentPubspec -replace 'msix_version:\s*\d+\.\d+\.\d+\.\d+', "msix_version: $msixVersion"
        [System.IO.File]::WriteAllText($pubspecPath, $currentPubspec, [System.Text.UTF8Encoding]::new($false))

        # Build Windows release
        $ErrorActionPreference = "Continue"
        flutter build windows --release
        $winExit = $LASTEXITCODE
        $ErrorActionPreference = "Stop"
        if ($winExit -ne 0) {
            Write-Fail "Windows build failed!"
            $failed = $true
        }
        else {
            Write-Ok "Windows built"
            $msixFile = $null
            $exeFile = $null

            # ========== MSIX INSTALLER (for Microsoft Store) ==========
            if ($buildMsix) {
                Write-Step "Creating MSIX installer (for Store)..."

                # Remove stale MSIX artifacts so we never pick an old package.
                $msixReleaseDir = Join-Path $root "build\windows\x64\runner\Release"
                if (Test-Path $msixReleaseDir) {
                    Get-ChildItem -Path $msixReleaseDir -Filter "*.msix" -ErrorAction SilentlyContinue |
                        Remove-Item -Force -ErrorAction SilentlyContinue
                }

                $ErrorActionPreference = "Continue"
                dart run msix:create
                $msixExit = $LASTEXITCODE
                $ErrorActionPreference = "Stop"

                if ($msixExit -ne 0) {
                    Write-Warn "MSIX creation failed"
                    if ($buildExe) { Write-Warn "Continuing with EXE only" }
                    Write-DeployLog "WINDOWS MSIX | FAILED"
                }
                else {
                    $msixFound = Get-ChildItem -Path (Join-Path $root "build\windows") -Filter "*.msix" -Recurse |
                        Sort-Object LastWriteTime -Descending |
                        Select-Object -First 1
                    if ($msixFound) {
                        $msixSize = "{0:N1} MB" -f ($msixFound.Length / 1MB)
                        Write-Ok "MSIX created ($msixSize) at $($msixFound.FullName)"
                        $msixFile = $msixFound.FullName
                        Write-DeployLog "WINDOWS MSIX | $msixSize | $($msixFound.Name)"
                    }
                    else {
                        Write-Warn "MSIX file not found in build output"
                        $msixFile = $null
                    }
                }
            }

            # ========== INNO SETUP EXE INSTALLER (for Web Download -- 85-90% coverage) ==========
            if ($buildExe) {
                Write-Step "Creating Inno Setup EXE installer (for web download)..."
                $issPath = Join-Path $root "installer\windows\TulasiRestaurants_Installer.iss"
                $isccPath = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
                $installerOutputDir = Join-Path $root "build\installer"

                if ((Test-Path $issPath) -and (Test-Path $isccPath)) {
                    New-Item -ItemType Directory -Path $installerOutputDir -Force | Out-Null

                    # Update version in .iss file
                    $issContent = Get-Content $issPath -Raw
                    $issContent = $issContent -replace '#define MyAppVersion "[\d.]+"', "#define MyAppVersion `"$newVersion`""
                    [System.IO.File]::WriteAllText($issPath, $issContent, [System.Text.UTF8Encoding]::new($false))
                    Write-Info "Updated .iss version to $newVersion"

                    # Compile with Inno Setup
                    $ErrorActionPreference = "Continue"
                    & $isccPath $issPath
                    $innoExit = $LASTEXITCODE
                    $ErrorActionPreference = "Stop"

                    if ($innoExit -ne 0) {
                        Write-Fail "Inno Setup compilation failed!"
                        if (-not $msixFile -and -not $buildMsix) {
                            $failed = $true
                        }
                        else {
                            Write-Warn "Continuing with MSIX only"
                        }
                    }
                    else {
                        $exeFile = Join-Path $root "build\installer\TulasiRestaurants_Setup.exe"
                        if (Test-Path $exeFile) {
                            $exeSize = "{0:N1} MB" -f ((Get-Item $exeFile).Length / 1MB)
                            Write-Ok "EXE installer created ($exeSize)"
                            Write-DeployLog "WINDOWS EXE | $exeSize"
                        }
                        else {
                            Write-Warn "EXE file not found at expected path"
                            $exeFile = $null
                        }
                    }
                }
                else {
                    if (-not (Test-Path $isccPath)) { Write-Warn "Inno Setup 6 not found at $isccPath" }
                    if (-not (Test-Path $issPath)) { Write-Warn "Inno Setup script not found at $issPath" }
                    if (-not $msixFile) { $failed = $true }
                }
            }

            # Check at least one installer was created
            if (-not $msixFile -and -not $exeFile) {
                Write-Fail "No installer created!"
                $failed = $true
            }

            if (-not $failed) {
                # Generate one-click VBS installer for MSIX
                if ($msixFile) {
                    Write-Step "Generating one-click MSIX installer script..."
                    $releaseDir = Join-Path $root "build\windows\x64\runner\Release"
                    $vbsInstaller = Join-Path $releaseDir "Install_TulasiRestaurants.vbs"
                    $msixFileName = [System.IO.Path]::GetFileName($msixFile)
                    $vbsContent = @"
' Tulasi Hotels - One-Click Installer v$newVersion
' Silently installs certificate, then opens MSIX installer GUI

If Not WScript.Arguments.Named.Exists("elevated") Then
    Set objShell = CreateObject("Shell.Application")
    objShell.ShellExecute "wscript.exe", """" & WScript.ScriptFullName & """ /elevated", "", "runas", 0
    WScript.Quit
End If

scriptDir = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))
msixFile = scriptDir & "$msixFileName"

Set fso = CreateObject("Scripting.FileSystemObject")
If Not fso.FileExists(msixFile) Then
    MsgBox "$msixFileName not found!" & vbCrLf & vbCrLf & "Please place this script in the same folder as the MSIX file.", vbExclamation, "Tulasi Hotels Installer"
    WScript.Quit 1
End If

Set objShell = CreateObject("WScript.Shell")
psCommand = "powershell -WindowStyle Hidden -ExecutionPolicy Bypass -Command """ & _
    "$msixPath = '" & msixFile & "'; " & _
    "$cert = (Get-AuthenticodeSignature $msixPath).SignerCertificate; " & _
    "if ($cert) { " & _
    "  $store = New-Object System.Security.Cryptography.X509Certificates.X509Store('TrustedPeople', 'LocalMachine'); " & _
    "  $store.Open('ReadWrite'); " & _
    "  $store.Add($cert); " & _
    "  $store.Close(); " & _
    "}" & """"

objShell.Run psCommand, 0, True
objShell.Run """" & msixFile & """", 1, False
WScript.Quit 0
"@
                    [System.IO.File]::WriteAllText($vbsInstaller, $vbsContent, [System.Text.UTF8Encoding]::new($false))
                    Write-Ok "Install_TulasiRestaurants.vbs generated"
                }

                # Update version.json with EXE download URL
                $winVersionPath = Join-Path $root "installer\version.json"
                $exeStorageName = "TulasiRestaurants_Setup.exe"
                $exeStorageNameWeb = "TulasiRestaurants_Setup_v$newVersion.exe"
                $exeDownloadUrl = "https://firebasestorage.googleapis.com/v0/b/login1-aa21c.firebasestorage.app/o/downloads%2Fwindows%2F$exeStorageNameWeb`?alt=media"

                $versionJson = @{
                    version        = $newVersion
                    buildNumber    = [int]$newBuild
                    exeDownloadUrl = $exeDownloadUrl
                    storeUrl       = "https://apps.microsoft.com/detail/tulasi-stores"
                    changelog      = $changelog
                    forceUpdate    = ($updateType -eq 3)
                } | ConvertTo-Json -Depth 3
                [System.IO.File]::WriteAllText($winVersionPath, $versionJson, [System.Text.UTF8Encoding]::new($false))
                Write-Ok "version.json updated (EXE download + Store URL)"

                # Auto-update website download page with new version
                $downloadPage = Join-Path $root "website\src\pages\download.html"
                if (Test-Path $downloadPage) {
                    Write-Step "Updating website download page..."
                    $pageContent = Get-Content $downloadPage -Raw
                    $exeDownloadUrlWeb = "https://firebasestorage.googleapis.com/v0/b/login1-aa21c.firebasestorage.app/o/downloads%2Fwindows%2F$exeStorageNameWeb`?alt=media"

                    # Update version display only (URLs are now fixed/stable)
                    $pageContent = $pageContent -replace '(<span>v)\d+\.\d+\.\d+(</span>)', "`${1}$newVersion`${2}"
                    $pageContent = $pageContent -replace '(Latest version: <strong>v)\d+\.\d+\.\d+(</strong>)', "`${1}$newVersion`${2}"
                    $pageContent = $pageContent -replace '(style="[^"]*">)\s*v\d+\.\d+\.\d+(</div>)', "`${1}v$newVersion`${2}"

                    # Update download attribute filenames (saved filename includes version)
                    $pageContent = $pageContent -replace 'download="TulasiRestaurants_Setup(?:_v[\d.]+)?\.exe"', "download=`"TulasiRestaurants_Setup_v$newVersion.exe`""
                    $pageContent = $pageContent -replace 'download="TulasiRestaurants(?:_v[\d.]+)?\.apk"', "download=`"TulasiRestaurants_v$newVersion.apk`""

                    # Keep EXE button URL versioned so browser download notifications show vX.Y.Z filename
                    $pageContent = $pageContent -replace '(id="windows-exe-btn"[^>]*href=")[^"]*(")', "`${1}$exeDownloadUrlWeb`${2}"

                    [System.IO.File]::WriteAllText($downloadPage, $pageContent, [System.Text.UTF8Encoding]::new($false))
                    Write-Ok "download.html updated to v$newVersion"
                    Write-DeployLog "WEBSITE | download.html updated to v$newVersion"
                }

                # Upload EXE to Firebase Storage (MSIX goes to Microsoft Store separately)
                $gsutilExists = Get-Command gsutil -ErrorAction SilentlyContinue
                if ($gsutilExists) {
                    $storagePath = "gs://login1-aa21c.firebasestorage.app/downloads/windows/"

                    # Upload version.json + EXE (overwrite single fixed filename)
                    Write-Step "Uploading EXE + version.json to Firebase Storage..."
                    gsutil cp $winVersionPath "${storagePath}version.json"
                    gsutil setmeta -h "Cache-Control:no-cache,max-age=0" "${storagePath}version.json"

                    if ($exeFile -and (Test-Path $exeFile)) {
                        gsutil cp $exeFile "${storagePath}$exeStorageName"
                        gsutil setmeta -h "Content-Type:application/octet-stream" -h "Cache-Control:no-cache,max-age=0" "${storagePath}$exeStorageName"
                        gsutil cp $exeFile "${storagePath}$exeStorageNameWeb"
                        gsutil setmeta -h "Content-Type:application/octet-stream" -h "Cache-Control:no-cache,max-age=0" "${storagePath}$exeStorageNameWeb"
                        Write-Ok "EXE uploaded: $exeStorageName"
                    }

                    $ErrorActionPreference = "Stop"
                    Write-Ok "EXE uploaded to Firebase Storage"
                    Write-DeployLog "FIREBASE UPLOAD | Windows EXE + version.json"
                }
                else {
                    Write-Warn "gsutil not found - upload EXE manually:"
                    Write-Info "  Firebase Console > Storage > updates/windows/"
                    Write-Info "  Upload: version.json + $exeStorageName"
                }

                # Remind to upload MSIX to Microsoft Store
                if ($msixFile -and (Test-Path $msixFile)) {
                    Write-Step "Microsoft Store: MSIX ready for upload"

                    # Copy MSIX path to clipboard
                    Set-Clipboard -Value $msixFile
                    Write-Ok "MSIX path copied to clipboard"

                    # Open MSIX folder in Explorer (so you can drag & drop)
                    Start-Process explorer.exe -ArgumentList "/select,`"$msixFile`""
                    Write-Ok "Opened MSIX file in Explorer"

                    # Open Partner Center packages page in browser
                    Start-Process "https://partner.microsoft.com/en-us/dashboard/apps-and-games/overview"
                    Write-Ok "Opened Partner Center in browser"

                    Write-Host ""
                    Write-Host "  +-------------------------------------------------+" -ForegroundColor Cyan
                    Write-Host "  |  MSIX: $msixFile" -ForegroundColor Yellow
                    Write-Host "  |                                                  |" -ForegroundColor Cyan
                    Write-Host "  |  Explorer + Partner Center opened for you!       |" -ForegroundColor Green
                    Write-Host "  |  Just drag the MSIX file and click Submit.       |" -ForegroundColor White
                    Write-Host "  +-------------------------------------------------+" -ForegroundColor Cyan
                    Read-Host "  Press Enter after done (or skip)"
                    Write-DeployLog "MSIX | $msixFile - Explorer + Partner Center opened"
                }
            }
            Complete-Step "windows"
        }
    }
    elseif (Test-StepDone "windows") {
        Write-Info "SKIP: Windows already built + uploaded"
    }

    # --- Prepare Android release for GitHub Actions ---
    if (-not $failed -and $deployAndroid -and -not (Test-StepDone "android")) {
        Write-Step "Preparing Android release for GitHub Actions..."
        $androidVersionPath = Join-Path $root "installer\android-version.json"
        $apkStorageName = "TulasiRestaurants_v$newVersion.apk"
        $apkDownloadUrl = "https://firebasestorage.googleapis.com/v0/b/login1-aa21c.firebasestorage.app/o/downloads%2Fandroid%2F$apkStorageName`?alt=media"
        $versionJson = @{
            version     = $newVersion
            buildNumber = [int]$newBuild
            downloadUrl = $apkDownloadUrl
            changelog   = $changelog
            forceUpdate = ($updateType -eq 3)
        } | ConvertTo-Json -Depth 3
        [System.IO.File]::WriteAllText($androidVersionPath, $versionJson, [System.Text.UTF8Encoding]::new($false))

        $downloadPage = Join-Path $root "website\src\pages\download.html"
        if (Test-Path $downloadPage) {
            $pageContent = Get-Content $downloadPage -Raw
            $pageContent = $pageContent -replace '(id="android-apk-btn"[^>]*href=")[^"]*(")', "`${1}$apkDownloadUrl`${2}"
            $pageContent = $pageContent -replace 'download="TulasiRestaurants(?:_v[\d.]+)?\.apk"', "download=`"$apkStorageName`""
            $pageContent = $pageContent -replace '(<strong>Version:</strong> v)\d+\.\d+\.\d+ \(Build \d+\)', "`${1}$newVersion (Build $newBuild)"
            [System.IO.File]::WriteAllText($downloadPage, $pageContent, [System.Text.UTF8Encoding]::new($false))
        }
        Write-Ok "Android release prepared; the final push triggers GitHub Actions to sign and upload it"
        Write-DeployLog "ANDROID CI QUEUED | v$newVersion+$newBuild"
        Complete-Step "android"
    }
    elseif (Test-StepDone "android") {
        Write-Info "SKIP: Android release already prepared for GitHub Actions"
    }

    # --- Deploy Website Only (no Flutter build) ---
    if (-not $failed -and $deployWebsiteOnly -and -not (Test-StepDone "website_only")) {
        Write-Step "Deploying Website Only (no Flutter build)..."
        $distDir = Join-Path $root "dist"
        $websiteDir = Join-Path $root "website"

        # Preserve existing app/ directory
        $appBackup = $null
        $appDir = Join-Path $distDir "app"
        if (Test-Path $appDir) {
            Write-Info "Preserving existing Flutter app (dist/app/)..."
            $appBackup = Join-Path $root "deploy-backups\app_temp_$((Get-Date -Format 'yyyyMMdd_HHmmss'))"
            New-Item -ItemType Directory -Path $appBackup -Force | Out-Null
            Copy-Item -Path "$appDir\*" -Destination $appBackup -Recurse -Force
        }

        if (Test-Path $distDir) { Remove-Item $distDir -Recurse -Force }
        New-Item -ItemType Directory -Path $distDir -Force | Out-Null
        Copy-Item -Path "$websiteDir\*" -Destination $distDir -Recurse -Force
        Write-Ok "Website copied to dist/"

        # Restore app/
        if ($appBackup) {
            $appDirNew = Join-Path $distDir "app"
            New-Item -ItemType Directory -Path $appDirNew -Force | Out-Null
            Copy-Item -Path "$appBackup\*" -Destination $appDirNew -Recurse -Force
            Remove-Item $appBackup -Recurse -Force
            Write-Ok "Flutter app restored to dist/app/"
        } else {
            Write-Warn "No existing Flutter app in dist/app/ -- website will deploy without /app/ route"
        }

        $serveJson = '{"rewrites":[{"source":"/app/**","destination":"/app/index.html"}],"headers":[{"source":"**/*","headers":[{"key":"Cache-Control","value":"no-cache"}]}]}'
        [System.IO.File]::WriteAllText((Join-Path $distDir "serve.json"), $serveJson, [System.Text.UTF8Encoding]::new($false))

        Write-Step "Deploying to Firebase Hosting..."
        $ErrorActionPreference = "Continue"
        firebase deploy --only hosting
        $fbExit = $LASTEXITCODE
        $ErrorActionPreference = "Stop"
        if ($fbExit -eq 0) {
            Write-Ok "Website deployed to Firebase Hosting!"
            Write-DeployLog "WEBSITE DEPLOYED"

            Write-Step "Health check..."
            Start-Sleep -Seconds 5
            $healthUrls = @(
                $websiteUrl,
                $appUrl
            )
            foreach ($url in $healthUrls) {
                try {
                    $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
                    if ($response.StatusCode -eq 200) { Write-Ok "$url -> HTTP 200" }
                    else { Write-Warn "$url -> HTTP $($response.StatusCode)" }
                }
                catch { Write-Warn "$url -> Could not reach" }
            }
            Write-DeployLog "HEALTH CHECK DONE"
        } else {
            Write-Fail "Firebase deploy failed!"
            $failed = $true
        }
        Complete-Step "website_only"
    }
    elseif (Test-StepDone "website_only") {
        Write-Info "SKIP: Website already deployed"
    }

    # --- Build and Deploy: Web --- [RUNS LAST so download.html has ALL updated links (Windows + Android)]
    if (-not $failed -and $deployWeb -and -not (Test-StepDone "web")) {
        Write-Step "Building Web..."
        $distDir = Join-Path $root "dist"
        $websiteDir = Join-Path $root "website"
        $flutterBuildDir = Join-Path $root "build\web"

        if (Test-Path $distDir) { Remove-Item $distDir -Recurse -Force }
        New-Item -ItemType Directory -Path $distDir -Force | Out-Null

        if (Test-Path $websiteDir) {
            Copy-Item -Path "$websiteDir\*" -Destination $distDir -Recurse -Force
            Write-Ok "Copied website/ to dist/"
        }

        $ErrorActionPreference = "Continue"
        flutter build web --base-href=/app/ --release
        $webExit = $LASTEXITCODE
        $ErrorActionPreference = "Stop"
        if ($webExit -ne 0) {
            Write-Fail "Web build failed!"
            $failed = $true
        }
        else {
            $appDir = Join-Path $distDir "app"
            New-Item -ItemType Directory -Path $appDir -Force | Out-Null
            Copy-Item -Path "$flutterBuildDir\*" -Destination $appDir -Recurse -Force
            Write-Ok "Web built to dist/app/"

            $serveJson = '{"rewrites":[{"source":"/app/**","destination":"/app/index.html"}],"headers":[{"source":"**/*","headers":[{"key":"Cache-Control","value":"no-cache"}]}]}'
            [System.IO.File]::WriteAllText((Join-Path $distDir "serve.json"), $serveJson, [System.Text.UTF8Encoding]::new($false))

            Write-Step "Deploying to Firebase Hosting..."
            $ErrorActionPreference = "Continue"
            firebase deploy --only hosting
            $fbExit = $LASTEXITCODE
            $ErrorActionPreference = "Stop"
            if ($fbExit -eq 0) {
                Write-Ok "Web deployed to Firebase Hosting!"
                Write-DeployLog "WEB DEPLOYED"

                Write-Step "Health check..."
                Start-Sleep -Seconds 5
                $healthUrls = @(
                    $websiteUrl,
                    $appUrl
                )
                foreach ($url in $healthUrls) {
                    try {
                        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
                        if ($response.StatusCode -eq 200) { Write-Ok "$url -> HTTP 200" }
                        else { Write-Warn "$url -> HTTP $($response.StatusCode)" }
                    }
                    catch {
                        Write-Warn "$url -> Could not reach"
                    }
                }
                Write-DeployLog "HEALTH CHECK DONE"
            }
            else {
                Write-Fail "Firebase deploy failed!"
                $failed = $true
            }
            Complete-Step "web"
        }
    }
    elseif (Test-StepDone "web") {
        Write-Info "SKIP: Web already built + deployed"
    }

    # --- All steps completed ---

}
catch {
    # Catch ANY unhandled PowerShell exception
    Write-Host ""
    Write-Fail "Unexpected error: $_"
    Write-DeployLog "ERROR | Unexpected: $_"
    $failed = $true
}

if ($failed) {
    Write-Host ""
    Write-Host "========================================================" -ForegroundColor Red
    Write-Host "  Deploy FAILED! Settings saved for resume." -ForegroundColor Red
    Write-Host "========================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Fix the error above, then re-run:" -ForegroundColor Yellow
    Write-Host "    .\smart-deploy.ps1" -ForegroundColor White
    Write-Host ""
    Write-Host "  It will resume with the same settings!" -ForegroundColor Gray
    Write-Host "  (State saved in deploy-state.json)" -ForegroundColor Gray
    Write-Host ""
    Write-DeployLog "DEPLOY FAILED | Settings saved for resume"
    exit 1
}

# --- SUCCESS! Clean up state file ---
if (Test-Path $statePath) {
    Remove-Item $statePath -Force
    Write-Info "deploy-state.json cleaned up"
}

# --- Remote Config (manual Firebase Console action) ---
if ($updateType -eq 3 -and $forceMinVersion) {
    Write-Step "MANUAL ACTION: Set Remote Config"
    Write-Host ""
    Write-Host "  +-------------------------------------------------+" -ForegroundColor Red
    Write-Host "  |  Go to Firebase Console > Remote Config          |" -ForegroundColor Red
    Write-Host "  |  Set: min_app_version = $forceMinVersion                  |" -ForegroundColor Yellow
    Write-Host "  |  Click: Publish Changes                          |" -ForegroundColor Yellow
    Write-Host "  |  WARNING: This BLOCKS users below v$forceMinVersion        |" -ForegroundColor Red
    Write-Host "  +-------------------------------------------------+" -ForegroundColor Red
    Read-Host "  Press Enter after done"
    Write-Ok "Force update configured"
    Write-DeployLog "REMOTE CONFIG | min_app_version = $forceMinVersion"
}

if ($updateType -eq 4) {
    Write-Step "MANUAL ACTION: Enable Maintenance Mode"
    Write-Host ""
    Write-Host "  +-------------------------------------------------+" -ForegroundColor Yellow
    Write-Host "  |  Go to Firebase Console > Remote Config          |" -ForegroundColor Yellow
    Write-Host "  |  Set: maintenance_mode = true                    |" -ForegroundColor Yellow
    Write-Host "  |  Click: Publish Changes                          |" -ForegroundColor Yellow
    Write-Host "  |  Set to false when done with maintenance         |" -ForegroundColor Gray
    Write-Host "  +-------------------------------------------------+" -ForegroundColor Yellow
    Read-Host "  Press Enter after done"
    Write-Ok "Maintenance mode enabled"
    Write-DeployLog "REMOTE CONFIG | maintenance_mode = true"
}

# --- Optional Remote Config ---
if ($setLatestVersion -or $announcementMsg) {
    Write-Step "MANUAL ACTION: Update Remote Config"
    Write-Host ""
    Write-Host "  Go to Firebase Console > Remote Config:" -ForegroundColor Yellow
    if ($setLatestVersion) {
        Write-Host "    Set: latest_version = $newVersion" -ForegroundColor Green
        Write-Host "         Users on older versions see Update available banner" -ForegroundColor Gray
    }
    if ($announcementMsg) {
        Write-Host "    Set: announcement = $announcementMsg" -ForegroundColor Cyan
        Write-Host "         ALL users see this banner. Set empty to remove." -ForegroundColor Gray
    }
    Write-Host "    Click: Publish Changes" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "  Press Enter after done"
    Write-Ok "Remote Config updated"
    if ($setLatestVersion) { Write-DeployLog "REMOTE CONFIG | latest_version = $newVersion" }
    if ($announcementMsg) { Write-DeployLog "REMOTE CONFIG | announcement = $announcementMsg" }
}

# --- Git Commit + Tag + Push ---
if ($deployWebsiteOnly) {
    Write-Step "Git commit + push (website)..."
    $ErrorActionPreference = "Continue"
    git add -A 2>&1 | Out-Null
    git commit -m "website: update marketing site" 2>&1 | Out-Null
    git push 2>&1 | Out-Null
    Write-Ok "Pushed to remote"
    Write-DeployLog "GIT | Website update pushed"
    $ErrorActionPreference = "Stop"
}
elseif (-not $skipBuild) {
    Write-Step "Git commit + tag + push..."
    $ErrorActionPreference = "Continue"
    git add -A 2>&1 | Out-Null
    $commitMsg = switch ($updateType) {
        1 { "release: v$newVersion+$newBuild" }
        2 { "fix: v$newVersion+$newBuild" }
        3 { "CRITICAL: v$newVersion+$newBuild" }
    }
    git commit -m $commitMsg 2>&1 | Out-Null
    git tag "v$newVersion+$newBuild" 2>&1 | Out-Null
    Write-Ok "Committed + tagged: v$newVersion+$newBuild"

    git push 2>&1 | Out-Null
    git push --tags 2>&1 | Out-Null
    Write-Ok "Pushed to remote"
    Write-DeployLog "GIT | Pushed v$newVersion+$newBuild"
    $ErrorActionPreference = "Stop"
}

# --- Cleanup old backups ---
if (Test-Path $backupDir) {
    $backups = Get-ChildItem $backupDir -Directory | Sort-Object Name -Descending
    if ($backups.Count -gt 5) {
        $toDelete = $backups | Select-Object -Skip 5
        foreach ($old in $toDelete) {
            Remove-Item $old.FullName -Recurse -Force
        }
        Write-Info "Cleaned $($toDelete.Count) old backups"
    }
}

# ===========================================================
#   DONE!
# ===========================================================
Write-Host ""
Write-Host "========================================================" -ForegroundColor Green
Write-Host "  Deploy Complete!" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host ""

if (-not $skipBuild -and -not $deployWebsiteOnly) {
    Write-Host "  Version: v$newVersion+$newBuild" -ForegroundColor White
}
Write-Host "  Type:    $($typeNames[$updateType])" -ForegroundColor White

if ($deployWebsiteOnly) { Write-Host "  Website: Deployed + Health Checked" -ForegroundColor Green }
if ($deployWeb) { Write-Host "  Web & Host: Flutter + Website Deployed + Health Checked" -ForegroundColor Green }
if ($deployWindows) { Write-Host "  Windows EXE: Built + Uploaded" -ForegroundColor Green }
if ($deployAndroid) { Write-Host "  Android APK: Built + Uploaded" -ForegroundColor Green }
if ($forceMinVersion) { Write-Host "  Force:   min_app_version = $forceMinVersion" -ForegroundColor Red }
if ($announcementMsg) { Write-Host "  Announce: $announcementMsg" -ForegroundColor Cyan }
if ($updateType -eq 4) { Write-Host "  Mode:    Maintenance ON" -ForegroundColor Yellow }
Write-Host ""
if ($deployWebsiteOnly) {
    Write-Host "  Website: $websiteUrl" -ForegroundColor White
    Write-Host "  App:     $appUrl" -ForegroundColor White
}
Write-Host "  Log: deploy-history.log" -ForegroundColor Gray
Write-Host ""

$versionTag = if ($deployWebsiteOnly) { "website-update" } else { "v$newVersion+$newBuild" }
Write-DeployLog "DEPLOY COMPLETE | $versionTag | $($typeNames[$updateType])"
Write-DeployLog "------------------------------------------------"

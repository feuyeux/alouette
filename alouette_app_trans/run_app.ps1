#!/usr/bin/env pwsh
# Quick start script for Alouette Translation
# Alouette Translation PowerShell Launch Script

param(
    [string]$Platform = "windows"
)

Write-Host "[START] Starting Alouette Translation" -ForegroundColor Blue

# Change to script directory
Set-Location -Path $PSScriptRoot

# Check pubspec.yaml
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "[ERROR] pubspec.yaml not found in $(Get-Location)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[INFO] Running from: $(Get-Location)" -ForegroundColor Green
Write-Host "[INFO] Platform: $Platform" -ForegroundColor Green

# Configure environment for Edge TTS to avoid proxy issues
# Edge TTS accesses Bing TTS endpoints; if a system/conda proxy is set, it may fail.
# Set NO_PROXY to bypass proxies for Bing domains during this session.
if (-not $env:NO_PROXY -or $env:NO_PROXY -eq "") {
    $env:NO_PROXY = "speech.platform.bing.com,.bing.com,*bing.com"
    Write-Host "[ENV] NO_PROXY set to: $env:NO_PROXY" -ForegroundColor Yellow
} else {
    Write-Host "[ENV] Existing NO_PROXY: $env:NO_PROXY" -ForegroundColor Yellow
}

# Completely remove any proxy environment variables for this session
foreach ($var in @(
    'HTTP_PROXY','HTTPS_PROXY','ALL_PROXY',
    'http_proxy','https_proxy','all_proxy'
)) {
    try { Remove-Item "Env:\$var" -ErrorAction Ignore } catch {}
}
Write-Host "[ENV] Removed HTTP(S)/ALL proxy vars (upper/lower case) for this session" -ForegroundColor Yellow

# Platform-specific setup (if needed in the future)
if ($Platform.ToLower() -eq "windows") {
    Write-Host "[SETUP] Preparing Windows environment..." -ForegroundColor Yellow
}

# Get dependencies and run application
Write-Host "[DEPS] Getting dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host "[LAUNCH] Launching Flutter app..." -ForegroundColor Green
flutter run -d $Platform --debug

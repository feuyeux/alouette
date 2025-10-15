#!/usr/bin/env pwsh
# Alouette Base App Quick Start Script (PowerShell)
#
# Usage:
#   .\run_app.ps1 [platform] [--no-clean] [--device=DEVICE_ID]
#
# Examples:
#   .\run_app.ps1                     # Run on Windows desktop with clean build (default)
#   .\run_app.ps1 android             # Run on Android with clean build
#   .\run_app.ps1 android --no-clean  # Run on Android without cleaning
#   .\run_app.ps1 chrome              # Run on Chrome
#   .\run_app.ps1 --device=emulator-5554  # Run on a specific device

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )

    Write-Host $Message -ForegroundColor $Color
}

function Get-EmulatorPath {
    $candidates = @($env:ANDROID_SDK_ROOT, $env:ANDROID_HOME) | Where-Object { $_ -and (Test-Path $_) }

    foreach ($root in $candidates) {
        $candidate = Join-Path $root "emulator\emulator.exe"
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    $fromPath = Get-Command emulator.exe -ErrorAction SilentlyContinue
    if ($fromPath) {
        return $fromPath.Source
    }

    return $null
}

function Invoke-FlutterDevices {
    param([switch]$Machine)

    $previousPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        $arguments = @("devices")
        if ($Machine) {
            $arguments += "--machine"
        }

        $result = flutter @arguments 2>&1
        return ,$result
    } finally {
        $ErrorActionPreference = $previousPreference
    }
}

function Get-AdbDevices {
    try {
        $adbOutput = adb devices 2>$null
        if (-not $adbOutput) {
            return @()
        }
        
        $deviceLines = $adbOutput -split [Environment]::NewLine | 
            Where-Object { $_ -match '^\S+\s+(device|offline|unauthorized)' }
        
        $deviceIds = @()
        foreach ($line in $deviceLines) {
            if ($line -match '^(\S+)\s+device') {
                $deviceIds += $Matches[1]
            }
        }
        
        return $deviceIds
    } catch {
        return @()
    }
}

function Get-AndroidDevices {
    $output = Invoke-FlutterDevices -Machine
    if (-not $output) {
        return @()
    }

    $textLines = $output | ForEach-Object { $_.ToString() }
    $jsonLines = $textLines | Where-Object { $_.Trim().StartsWith("[") -or $_.Trim().StartsWith("{") }
    if (-not $jsonLines) {
        return @()
    }

    $json = ($jsonLines -join [Environment]::NewLine).Trim()
    if (-not $json) {
        return @()
    }

    try {
        $devices = $json | ConvertFrom-Json
        return @($devices | Where-Object { $_.targetPlatform -like 'android*' })
    } catch {
        return @()
    }
}

function Start-AndroidEmulator {
    Write-ColorOutput "[ANDROID] No devices detected, attempting to start emulator..." "Yellow"

    $emulatorPath = Get-EmulatorPath
    if (-not $emulatorPath) {
        Write-ColorOutput "[ERROR] Unable to locate Android emulator. Ensure ANDROID_HOME or ANDROID_SDK_ROOT is set." "Red"
        return $false
    }

    $avds = & $emulatorPath -list-avds 2>$null
    if (-not $avds) {
        Write-ColorOutput "[ERROR] No Android Virtual Devices found. Create one with AVD Manager." "Red"
        return $false
    }

    $defaultAvd = ($avds | Where-Object { $_.Trim() } | Select-Object -First 1).Trim()
    if (-not $defaultAvd) {
        Write-ColorOutput "[ERROR] Unable to determine default AVD." "Red"
        return $false
    }

    Write-ColorOutput "[ANDROID] Starting emulator '$defaultAvd'..." "Cyan"
    Start-Process -FilePath $emulatorPath -ArgumentList "-avd", $defaultAvd | Out-Null
    return $true
}

function Wait-ForAndroidDevice {
    param([int]$TimeoutSeconds = 90)

    Write-ColorOutput "[ANDROID] Waiting for Android emulator/device..." "Yellow"

    for ($elapsed = 0; $elapsed -lt $TimeoutSeconds; $elapsed++) {
        $adbDevices = Get-AdbDevices
        if ($adbDevices.Count -gt 0) {
            Write-ColorOutput "[ANDROID] ADB detected device(s): $($adbDevices -join ', ')" "Green"
            return $adbDevices
        }

        if ($elapsed % 5 -eq 0 -and $elapsed -gt 0) {
            Write-Host "." -NoNewline
        }
        Start-Sleep -Seconds 1
    }

    Write-Host ""
    return @()
}

Write-ColorOutput "[START] Starting Alouette Base App" "Blue"

Set-Location $scriptDir

if (!(Test-Path "pubspec.yaml")) {
    Write-ColorOutput "[ERROR] pubspec.yaml not found in $(Get-Location)" "Red"
    exit 1
}

$clean = $true
$platform = "windows"
$deviceId = $null
$isIos = $false
$isAndroid = $false

foreach ($arg in $args) {
    switch -Regex ($arg) {
        '^--no-clean$' {
            $clean = $false
            continue
        }
        '^--device=(.+)$' {
            $deviceId = $Matches[1]
            continue
        }
        '^(macos|linux|windows|chrome|edge|android|ios)$' {
            $platform = $Matches[1]
            $isIos = $platform -eq 'ios'
            $isAndroid = $platform -eq 'android'
            continue
        }
        default {
            Write-ColorOutput "[WARN] Ignoring unrecognized argument '$arg'" "Yellow"
        }
    }
}

if ($deviceId) {
    if ($platform -eq 'android') {
        $isAndroid = $true
    } elseif ($platform -eq 'ios') {
        $isIos = $true
    }
    $platform = $deviceId
}

Write-ColorOutput "[INFO] Running from: $(Get-Location)" "Green"
Write-ColorOutput "[INFO] Target: $platform" "Green"
if ($clean) {
    Write-ColorOutput "[INFO] Clean build enabled" "Green"
} else {
    Write-ColorOutput "[INFO] Fast build (no clean)" "Green"
}

if ($isAndroid -and -not $deviceId) {
    # 首先检查 ADB 是否已经能看到设备
    $adbDevices = Get-AdbDevices
    
    if ($adbDevices.Count -gt 0) {
        Write-ColorOutput "[ANDROID] ADB already detects device(s): $($adbDevices -join ', ')" "Green"
    } else {
        # 没有任何设备，尝试启动模拟器
        if (Start-AndroidEmulator) {
            $adbDevices = Wait-ForAndroidDevice
        }
    }

    if ($adbDevices.Count -eq 0) {
        Write-ColorOutput "[ERROR] Unable to detect Android device or start emulator." "Red"
        Write-ColorOutput "[TIP] Start an emulator via Android Studio or connect a device." "Yellow"
        exit 1
    }

    # 优先选择模拟器，否则选第一个设备
    $selectedDeviceId = $adbDevices | Where-Object { $_ -like 'emulator-*' } | Select-Object -First 1
    if (-not $selectedDeviceId) {
        $selectedDeviceId = $adbDevices | Select-Object -First 1
    }

    Write-ColorOutput "[ANDROID] Selected device: $selectedDeviceId" "Green"
    $platform = $selectedDeviceId
}

if ($clean) {
    Write-ColorOutput "[CLEAN] Cleaning project..." "Yellow"
    try {
        flutter clean | Out-Null
        if ($isAndroid) {
            Remove-Item -Path "android\build" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "android\app\build" -Recurse -Force -ErrorAction SilentlyContinue
        }
        Write-ColorOutput "[SUCCESS] Clean complete" "Green"
    } catch {
        Write-ColorOutput "[WARNING] Clean failed, continuing..." "Yellow"
    }

    Write-ColorOutput "[DEPS] Getting dependencies..." "Yellow"
    try {
        flutter pub get | Out-Null
        Write-ColorOutput "[SUCCESS] Dependencies updated" "Green"
    } catch {
        Write-ColorOutput "[ERROR] Failed to get dependencies" "Red"
        exit 1
    }
}

Write-ColorOutput "[LAUNCH] Launching Flutter app..." "Green"
try {
    flutter run -d $platform --debug
} catch {
    Write-ColorOutput "[ERROR] Failed to start application: $_" "Red"
    exit 1
}

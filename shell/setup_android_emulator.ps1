#!/usr/bin/env pwsh

# PowerShell equivalent of setup_android_emulator.sh

$ErrorActionPreference = 'Stop'

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO]  $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK]    $Message" -ForegroundColor Green
}

function Write-WarningMessage {
    param([string]$Message)
    Write-Host "[WARN]  $Message" -ForegroundColor Yellow
}

function Write-ErrorMessage {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Show-Help {
    Write-Host @"
Android Emulator Setup (PowerShell)
Usage: ./setup_android_emulator.ps1 [install|start|status|help]

Commands:
  install  Install system image and create emulator
  start    Launch the configured emulator
  status   Show available devices and emulators
  help     Display this help text

Configuration:
  Emulator name : android_pixel
  Android API   : 34
  System image  : system-images;android-34;google_apis_playstore;arm64-v8a
  Device profile: pixel_7

Examples:
  ./setup_android_emulator.ps1 install
  ./setup_android_emulator.ps1 start
  ./setup_android_emulator.ps1 status
"@
}

$EMULATOR_NAME = 'android_pixel'
$ANDROID_API = '34'
$SYSTEM_IMAGE = "system-images;android-$ANDROID_API;google_apis_playstore;arm64-v8a"
$DEVICE_PROFILE = 'pixel_7'

function Check-Architecture {
    Write-Info 'Checking system architecture...'
    $arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLowerInvariant()
    switch ($arch) {
        'arm64' {
            Write-Success 'ARM64 architecture detected. Using ARM64 system image.'
        }
        'x64' {
            Write-WarningMessage 'x64 architecture detected. The default image targets ARM64.'
            Write-WarningMessage 'Adjust SYSTEM_IMAGE if you need an x86_64 image.'
            $answer = Read-Host 'Continue with current settings? (y/n)'
            if ($answer -notmatch '^(y|Y)$') { exit 1 }
        }
        default {
            Write-ErrorMessage "Unsupported architecture: $arch"
            exit 1
        }
    }
}

function Ensure-Command {
    param([string]$CommandName, [string]$InstallHint)

    if (-not (Get-Command $CommandName -ErrorAction SilentlyContinue)) {
        Write-ErrorMessage "$CommandName not found."
        if ($InstallHint) {
            Write-Info $InstallHint
        }
        exit 1
    }
}

function Check-Requirements {
    Write-Info 'Validating toolchain...'
    Ensure-Command -CommandName 'flutter' -InstallHint 'Install Flutter from https://flutter.dev/docs/get-started/install'
    $flutterVersion = (& flutter --version 2>$null | Select-Object -First 1).Trim()
    Write-Success "Flutter detected: $flutterVersion"

    Ensure-Command -CommandName 'sdkmanager' -InstallHint 'Run "flutter doctor --android-licenses" to install Android SDK tools.'
    Write-Success 'Android SDK manager detected.'

    Ensure-Command -CommandName 'avdmanager' -InstallHint 'Ensure Android SDK cmdline-tools are installed.'
    Write-Success 'AVD manager detected.'
}

function Install-SystemImage {
    Write-Info 'Checking for required system image...'
    $listOutput = & sdkmanager --list
    if ($listOutput | Select-String -Pattern [Regex]::Escape($SYSTEM_IMAGE)) {
        Write-Success "System image already installed: $SYSTEM_IMAGE"
        return
    }

    Write-Info "Installing Android $ANDROID_API system image ($SYSTEM_IMAGE)..."
    Write-WarningMessage 'This download may take several minutes.'
    try {
        'y','y','y' | & sdkmanager $SYSTEM_IMAGE *> $null
    } catch {
        Write-ErrorMessage 'Failed to install system image.'
        throw
    }
    Write-Success 'System image installation complete.'
}

function Create-Emulator {
    Write-Info "Checking emulator definition $EMULATOR_NAME..."
    $existing = & avdmanager list avd 2>$null
    if ($existing | Select-String -SimpleMatch "Name: $EMULATOR_NAME") {
        Write-WarningMessage "Emulator '$EMULATOR_NAME' already exists."
        $answer = Read-Host 'Delete and recreate? (y/n)'
        if ($answer -match '^(y|Y)$') {
            Write-Info 'Removing existing emulator...'
            & avdmanager delete avd -n $EMULATOR_NAME | Out-Null
            Write-Success 'Previous emulator removed.'
        } else {
            Write-Info 'Keeping existing emulator definition.'
            return
        }
    }

    Write-Info "Creating emulator '$EMULATOR_NAME' using profile $DEVICE_PROFILE..."
    try {
        'no' | & avdmanager create avd -n $EMULATOR_NAME -k $SYSTEM_IMAGE -d $DEVICE_PROFILE | Out-Null
    } catch {
        Write-ErrorMessage 'Failed to create emulator.'
        throw
    }
    Write-Success 'Emulator created successfully.'
}

function Start-Emulator {
    Write-Info 'Checking emulator availability...'
    $existing = & avdmanager list avd 2>$null
    if (-not ($existing | Select-String -SimpleMatch "Name: $EMULATOR_NAME")) {
        Write-ErrorMessage "Emulator '$EMULATOR_NAME' not found. Run install first."
        exit 1
    }

    $deviceList = & flutter devices 2>$null
    if ($deviceList | Select-String -Pattern 'emulator-') {
        Write-WarningMessage 'An Android emulator is already running.'
        $deviceList | Select-String -Pattern 'emulator-'
        return
    }

    Write-Info "Launching emulator '$EMULATOR_NAME'..."
    Start-Process -FilePath (Get-Command flutter).Source -ArgumentList @('emulators','--launch',$EMULATOR_NAME) -WindowStyle Hidden | Out-Null

    Write-Info 'Waiting for emulator to boot...'
    $maxWait = 60
    $elapsed = 0
    while ($elapsed -lt $maxWait) {
        Start-Sleep -Seconds 2
        $elapsed += 2
        $deviceList = & flutter devices 2>$null
        if ($deviceList | Select-String -Pattern 'emulator-') {
            Write-Success 'Emulator started successfully.'
            $deviceList | Select-String -Pattern 'emulator-'
            return
        }
    }

    Write-ErrorMessage 'Timed out waiting for emulator to start.'
    Write-Info 'Open Android Studio and review the AVD Manager for details.'
    exit 1
}

function Show-Status {
    Write-Info 'Flutter devices:'
    & flutter devices
    Write-Host ''
    Write-Info 'Flutter emulators:'
    & flutter emulators
    Write-Host ''

    $existing = & avdmanager list avd 2>$null
    if ($existing | Select-String -SimpleMatch "Name: $EMULATOR_NAME") {
        Write-Success "Emulator '$EMULATOR_NAME' is configured."
    } else {
        Write-WarningMessage "Emulator '$EMULATOR_NAME' is not configured."
        Write-Info "Run ./setup_android_emulator.ps1 install to create it."
    }
}

$command = if ($args.Count -gt 0) { $args[0].ToLowerInvariant() } else { 'help' }

switch ($command) {
    'install' {
        Write-Info 'Starting install workflow...'
        Check-Architecture
        Check-Requirements
        Install-SystemImage
        Create-Emulator
        Write-Host ''
        Write-Success 'Installation workflow complete.'
        Write-Info 'Next steps:'
        Write-Info '1. Run ./setup_android_emulator.ps1 start to launch the emulator.'
        Write-Info '2. Use flutter run -d emulator-5554 inside your Flutter project.'
    }
    'start' {
        Start-Emulator
    }
    'status' {
        Show-Status
    }
    'help' {
        Show-Help
    }
    default {
        Write-ErrorMessage "Unknown command: $command"
        Show-Help
        exit 1
    }
}

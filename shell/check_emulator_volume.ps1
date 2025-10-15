#!/usr/bin/env pwsh
# Script to check and maximize Android emulator volume

Write-Host "[INFO] Checking Android emulator volume settings..." -ForegroundColor Cyan

# Get list of devices
$devices = adb devices | Select-String "emulator"
if ($devices.Count -eq 0) {
    Write-Host "[ERROR] No Android emulator found" -ForegroundColor Red
    exit 1
}

# Use first device
$device = ($devices[0] -split '\s+')[0]
Write-Host "[INFO] Using device: $device" -ForegroundColor Green

# Check current media volume
Write-Host "`n[INFO] Current volume settings:" -ForegroundColor Cyan
adb -s $device shell "dumpsys audio | grep -A5 'STREAM_MUSIC'"

# Set media volume to maximum (15 is typically max on Android)
Write-Host "`n[INFO] Setting media volume to maximum..." -ForegroundColor Yellow
for ($i = 0; $i -lt 20; $i++) {
    adb -s $device shell "input keyevent 24" | Out-Null  # Volume UP
}

Write-Host "[SUCCESS] Volume maximized" -ForegroundColor Green

# Verify new volume
Write-Host "`n[INFO] New volume settings:" -ForegroundColor Cyan
adb -s $device shell "dumpsys audio | grep -A5 'STREAM_MUSIC'"

Write-Host "`n[INFO] You can also adjust volume manually:" -ForegroundColor Cyan
Write-Host "  - Volume UP:   adb -s $device shell input keyevent 24" -ForegroundColor White
Write-Host "  - Volume DOWN: adb -s $device shell input keyevent 25" -ForegroundColor White

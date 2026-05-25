# PowerShell script to deploy the robust, auto-patching, dynamic DNS-capable wrappers to the target phone via ADB.
# This script is fully trackable, reusable, and unified under the zflip3-recovery-runbook repository.

$ErrorActionPreference = "Stop"

# Ensure ADB is running and device is connected
Write-Host "Checking for connected ADB devices..." -ForegroundColor Cyan
$devices = adb devices | Select-String "device\b"

if (-not $devices) {
    Write-Error "No ADB devices connected! Make sure your Z Flip 3 is connected via USB, authorized, and showing as 'device' in 'adb devices'."
}

Write-Host "Found device. Deploying dynamic wrappers..." -ForegroundColor Green

# Define local paths
$LocalDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PatcherLocal = Join-Path $LocalDir "termux\patch_agy_va39.py"
$UpdaterLocal = Join-Path $LocalDir "termux\update_agy.py"
$WrapperLocal = Join-Path $LocalDir "termux\agy-va39"

# Define remote paths
$HomeRemote = "/data/data/com.termux/files/home"
$BinRemote = "$HomeRemote/.local/bin"

# Push files to target device
Write-Host "Pushing patch_agy_va39.py..." -ForegroundColor Cyan
adb push $PatcherLocal "$HomeRemote/patch_agy_va39.py"

Write-Host "Pushing update_agy.py..." -ForegroundColor Cyan
adb push $UpdaterLocal "$HomeRemote/update_agy.py"

Write-Host "Pushing agy-va39 wrapper..." -ForegroundColor Cyan
# Ensure remote directory exists
adb shell "mkdir -p $BinRemote"
adb push $WrapperLocal "$BinRemote/agy-va39"

# Set proper ownership and execution permissions on the phone
Write-Host "Setting remote permissions..." -ForegroundColor Cyan
adb shell "chmod +x $HomeRemote/patch_agy_va39.py"
adb shell "chmod +x $HomeRemote/update_agy.py"
adb shell "chmod +x $BinRemote/agy-va39"
adb shell "chown u0_a315:u0_a315 $HomeRemote/patch_agy_va39.py $HomeRemote/update_agy.py $BinRemote/agy-va39"

Write-Host "`n✓ Deployment successful! The dynamic wrappers are fully trackable, reusable, and active on the device." -ForegroundColor Green

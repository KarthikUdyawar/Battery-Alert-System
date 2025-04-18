<#
.SYNOPSIS
    Installer for Battery Alert System
.DESCRIPTION
    Sets up the Battery Alert System to run at Windows startup
.NOTES
    Author: KarthikUdyawar
    Date: April 18, 2025
#>

# Ensure script is running with admin privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script requires administrative privileges. Please run as Administrator." -ForegroundColor Red
    exit
}

Write-Host "Battery Alert System - Windows Installer" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# Get the script directory
$scriptDir = $PSScriptRoot
if (-not $scriptDir) {
    $scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
}

$monitorScript = Join-Path -Path $scriptDir -ChildPath "BatteryMonitor.ps1"

# Create startup script
$startupScript = @"
powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "$monitorScript"
"@

# Create a batch file in the startup folder
$startupPath = [Environment]::GetFolderPath('Startup')
$batchFile = Join-Path -Path $startupPath -ChildPath "StartBatteryMonitor.bat"

Write-Host "Creating startup file at: $batchFile" -ForegroundColor Yellow
Set-Content -Path $batchFile -Value $startupScript -Force

# Create task scheduler task (more reliable than startup folder)
Write-Host "Creating scheduled task..." -ForegroundColor Yellow

$taskName = "BatteryMonitorSystem"
$taskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($taskExists) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$monitorScript`""
$trigger = New-ScheduledTaskTrigger -AtLogon
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description "Battery Monitor System" -RunLevel Highest

# Set PowerShell execution policy to allow the script to run
Write-Host "Setting PowerShell execution policy..." -ForegroundColor Yellow
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force

Write-Host "`nInstallation Complete!" -ForegroundColor Green
Write-Host "The Battery Alert System has been installed and will start automatically at system startup." -ForegroundColor White

# Ask if user wants to start the script now
$startNow = Read-Host "Do you want to start the battery monitor now? (y/n)"
if ($startNow -eq "y" -or $startNow -eq "Y") {
    Write-Host "Starting Battery Monitor..." -ForegroundColor Green
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$monitorScript`""
    Write-Host "Battery Monitor started in background" -ForegroundColor Green
} else {
    Write-Host "Battery Monitor will start on next system boot" -ForegroundColor Yellow
}

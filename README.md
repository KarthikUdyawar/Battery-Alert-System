# Battery Alert System

A Windows-based battery monitoring system that alerts users when their laptop battery level falls below 20% or rises above 95%. This helps prevent battery drain and optimize battery health by avoiding overcharging.

## Features

- Windows PowerShell implementation
- Audio notifications when battery thresholds are reached
- Desktop notifications via Windows Toast notifications
- Text-to-speech alerts
- Automatic startup configuration
- Customizable battery level thresholds

## Requirements

- Windows 10 or newer
- PowerShell 5.1 or newer

## Installation

### Automatic Installation

1. Right-click on `Install-BatteryMonitor.ps1` and select "Run with PowerShell as Administrator"
2. Follow the on-screen instructions
3. The script will be configured to run at startup automatically

### Manual Installation

1. Right-click on PowerShell and select "Run as Administrator"
2. Set execution policy to allow scripts:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
   ```
3. Add the script to startup:
   - **Method 1**: Create a scheduled task
     ```powershell
     $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File 'C:\path\to\BatteryMonitor.ps1'"
     $trigger = New-ScheduledTaskTrigger -AtLogon
     $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
     Register-ScheduledTask -TaskName "BatteryMonitorSystem" -Action $action -Trigger $trigger -Settings $settings -Description "Battery Monitor System"
     ```
   - **Method 2**: Add to Startup folder
     ```powershell
     $startup = [Environment]::GetFolderPath('Startup')
     $shortcut = Join-Path $startup "BatteryMonitor.lnk"
     $WshShell = New-Object -ComObject WScript.Shell
     $Shortcut = $WshShell.CreateShortcut($shortcut)
     $Shortcut.TargetPath = "powershell.exe"
     $Shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File 'C:\path\to\BatteryMonitor.ps1'"
     $Shortcut.Save()
     ```

## Customization

You can modify the battery thresholds by editing the `BatteryMonitor.ps1` file:

```powershell
# Configuration variables
$LOW_THRESHOLD = 20  # Change to your preferred low battery threshold
$HIGH_THRESHOLD = 95  # Change to your preferred high battery threshold
$CHECK_INTERVAL = 60  # Change how often the script checks battery status (in seconds)
```

## Running the Script

To run the script manually:

1. Right-click on PowerShell and select "Run as Administrator"
2. Navigate to the script directory
3. Execute the script:
   ```powershell
   .\BatteryMonitor.ps1
   ```

## Troubleshooting

### PowerShell Execution Policy Issues

If you encounter execution policy issues:

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
```

### Notifications Not Working

Ensure you have the required permissions for notifications:
1. Go to Windows Settings > System > Notifications & actions
2. Make sure notifications are enabled

### Battery Information Not Available

If the script cannot detect your battery:
1. Verify your device has a battery
2. Run the following command to check if Windows can detect your battery:
   ```powershell
   Get-WmiObject -Class Win32_Battery
   ```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

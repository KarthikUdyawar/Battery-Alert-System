<#
.SYNOPSIS
    Battery Alert System for Windows laptops
.DESCRIPTION
    Monitors battery level and alerts when battery falls below 20% or exceeds 95%
    Provides audio and visual notifications using native Windows features
.NOTES
    Author: KarthikUdyawar
    Date: April 18, 2025
#>

# Configuration variables
$LOW_THRESHOLD = 20
$HIGH_THRESHOLD = 95
$CHECK_INTERVAL = 60  # Check battery every 60 seconds

# Function to get battery percentage
function Get-BatteryPercentage {
    $batteryInfo = Get-WmiObject -Class Win32_Battery
    if ($batteryInfo) {
        return $batteryInfo.EstimatedChargeRemaining
    } else {
        Write-Host "No battery found or unable to retrieve battery information."
        return $null
    }
}

# Function to get charging status
function Get-ChargingStatus {
    $batteryInfo = Get-WmiObject -Class Win32_Battery
    if ($batteryInfo) {
        # BatteryStatus: 1 = discharging, 2 = AC connected, others vary
        if ($batteryInfo.BatteryStatus -eq 2) {
            return "charging"
        } else {
            return "discharging"
        }
    } else {
        return "unknown"
    }
}

# Function to show notification
function Show-Notification {
    param (
        [string]$Title,
        [string]$Message
    )
    
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
    $template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
    
    $toastXml = [xml]$template.GetXml()
    $toastXml.GetElementsByTagName("text")[0].AppendChild($toastXml.CreateTextNode($Title)) > $null
    $toastXml.GetElementsByTagName("text")[1].AppendChild($toastXml.CreateTextNode($Message)) > $null
    
    $toast = [Windows.UI.Notifications.ToastNotification]::new($toastXml)
    $toast.Tag = "BatteryAlert"
    $toast.Group = "BatteryMonitor"
    $toast.ExpirationTime = [DateTimeOffset]::Now.AddMinutes(1)
    
    $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("BatteryMonitor")
    $notifier.Show($toast)
    
    # Fallback for older Windows versions
    if (-not $?) {
        Add-Type -AssemblyName System.Windows.Forms
        $notification = New-Object System.Windows.Forms.NotifyIcon
        $notification.Icon = [System.Drawing.SystemIcons]::Information
        $notification.BalloonTipTitle = $Title
        $notification.BalloonTipText = $Message
        $notification.Visible = $true
        $notification.ShowBalloonTip(5000)
    }
}

# Function to play audio notification
function Invoke-AudioNotification {
    param (
        [string]$Message
    )
    
    # Play system sound
    [System.Media.SystemSounds]::Exclamation.Play()
    
    # Text-to-speech notification
    Add-Type -AssemblyName System.Speech
    $speech = New-Object System.Speech.Synthesis.SpeechSynthesizer
    $speech.Speak($Message)
}

# Main monitoring loop
function Start-BatteryMonitor {
    Write-Host "Starting Battery Monitor..."
    Write-Host "Monitoring battery level (Low: $LOW_THRESHOLD%, High: $HIGH_THRESHOLD%)"
    
    # Variables to track if alerts have been shown
    $lowAlertShown = $false
    $highAlertShown = $false
    
    while ($true) {
        $batteryPercentage = Get-BatteryPercentage
        $chargingStatus = Get-ChargingStatus
        
        # Skip this iteration if we couldn't get battery info
        if ($null -eq $batteryPercentage) {
            Write-Host "Could not get battery percentage. Retrying in $CHECK_INTERVAL seconds..."
            Start-Sleep -Seconds $CHECK_INTERVAL
            continue
        }
        
        $currentTime = Get-Date -Format "HH:mm:ss"
        Write-Host "[$currentTime] Battery: $batteryPercentage% ($chargingStatus)"
        
        # Check for low battery condition
        if (($batteryPercentage -le $LOW_THRESHOLD) -and ($chargingStatus -eq "discharging")) {
            if (-not $lowAlertShown) {
                $message = "Warning: Battery level is low ($batteryPercentage%). Please connect charger."
                Write-Host $message -ForegroundColor Red
                Show-Notification -Title "Low Battery Alert" -Message $message
                Invoke-AudioNotification -Message $message
                $lowAlertShown = $true
            }
        } else {
            $lowAlertShown = $false
        }
        
        # Check for high battery condition
        if (($batteryPercentage -ge $HIGH_THRESHOLD) -and ($chargingStatus -eq "charging")) {
            if (-not $highAlertShown) {
                $message = "Notice: Battery level is high ($batteryPercentage%). Consider unplugging charger."
                Write-Host $message -ForegroundColor Yellow
                Show-Notification -Title "High Battery Alert" -Message $message
                Play-AudioNotification -Message $message
                $highAlertShown = $true
            }
        } else {
            $highAlertShown = $false
        }
        
        # Wait before checking again
        Start-Sleep -Seconds $CHECK_INTERVAL
    }
}

# Start monitoring
Start-BatteryMonitor

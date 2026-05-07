param(
    [Alias("IntervalSeconds")]
    [int]$PressIntervalSeconds = 5,
    [int]$MoveIntervalMilliseconds = 1000,
    [int]$Pixels = 1,
    [int]$EndTimeHours = $null,
    [int]$EndTimeMinutes = $null,
    [bool]$ShutdownAfter = $false
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$signature = @"
using System;
using System.Runtime.InteropServices;

public static class MouseJigglerNative
{
    [DllImport("user32.dll")]
    public static extern bool GetCursorPos(out POINT lpPoint);

    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int X, int Y);

    [DllImport("user32.dll")]
    public static extern void mouse_event(uint dwFlags, uint dx, uint dy, uint dwData, UIntPtr dwExtraInfo);

    public struct POINT
    {
        public int X;
        public int Y;
    }
}
"@

Add-Type -TypeDefinition $signature

$mouseEventLeftDown = 0x0002
$mouseEventLeftUp = 0x0004
$script:Direction = 1
$script:IsPressingButton = $false
$script:PressCount = 0
$script:EndTime = $null
$script:ShutdownAfter = $ShutdownAfter

[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = "MouseJiggler"
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $true
$form.ClientSize = New-Object System.Drawing.Size(360, 280)
$form.KeyPreview = $true

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "MouseJiggler laeuft"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$titleLabel.AutoSize = $true
$titleLabel.Location = New-Object System.Drawing.Point(24, 22)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Button wurde noch nicht gedrueckt."
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$statusLabel.AutoSize = $true
$statusLabel.Location = New-Object System.Drawing.Point(26, 58)

$button = New-Object System.Windows.Forms.Button
$button.Text = "Automatischer Druck"
$button.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$button.Size = New-Object System.Drawing.Size(200, 42)
$button.Location = New-Object System.Drawing.Point(80, 96)

$button.Add_Click({
    $script:PressCount++
    $statusLabel.Text = "Button gedrueckt: $script:PressCount"
})

$endTimeLabel = New-Object System.Windows.Forms.Label
$endTimeLabel.Text = "Endzeit (optional):"
$endTimeLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$endTimeLabel.AutoSize = $true
$endTimeLabel.Location = New-Object System.Drawing.Point(26, 152)

$hoursLabel = New-Object System.Windows.Forms.Label
$hoursLabel.Text = "Stunden:"
$hoursLabel.AutoSize = $true
$hoursLabel.Location = New-Object System.Drawing.Point(26, 178)

$hoursInput = New-Object System.Windows.Forms.TextBox
$hoursInput.Width = 50
$hoursInput.Location = New-Object System.Drawing.Point(90, 175)
$hoursInput.Text = "00"

$minutesLabel = New-Object System.Windows.Forms.Label
$minutesLabel.Text = "Minuten:"
$minutesLabel.AutoSize = $true
$minutesLabel.Location = New-Object System.Drawing.Point(155, 178)

$minutesInput = New-Object System.Windows.Forms.TextBox
$minutesInput.Width = 50
$minutesInput.Location = New-Object System.Drawing.Point(220, 175)
$minutesInput.Text = "00"

$setEndTimeButton = New-Object System.Windows.Forms.Button
$setEndTimeButton.Text = "Endzeit setzen"
$setEndTimeButton.Size = New-Object System.Drawing.Size(100, 28)
$setEndTimeButton.Location = New-Object System.Drawing.Point(26, 206)

$endTimeStatusLabel = New-Object System.Windows.Forms.Label
$endTimeStatusLabel.Text = "Keine Endzeit gesetzt."
$endTimeStatusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$endTimeStatusLabel.AutoSize = $true
$endTimeStatusLabel.Location = New-Object System.Drawing.Point(135, 212)

$shutdownCheckbox = New-Object System.Windows.Forms.CheckBox
$shutdownCheckbox.Text = "Computer herunterfahren"
$shutdownCheckbox.AutoSize = $true
$shutdownCheckbox.Location = New-Object System.Drawing.Point(26, 242)
$shutdownCheckbox.Checked = $ShutdownAfter

$setEndTimeButton.Add_Click({
    try {
        $hours = [int]$hoursInput.Text
        $minutes = [int]$minutesInput.Text

        if ($hours -lt 0 -or $hours -gt 23 -or $minutes -lt 0 -or $minutes -gt 59) {
            [System.Windows.Forms.MessageBox]::Show(
                "Bitte geben Sie gueltiges Zeit an!`nStunden: 0-23`nMinuten: 0-59",
                "Ungueltige Uhrzeit",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            return
        }

        $now = Get-Date
        $endTime = $now.AddDays(0) -replace $now.TimeOfDay, (New-TimeSpan -Hours $hours -Minutes $minutes)
        $endTime = Get-Date -Year $now.Year -Month $now.Month -Day $now.Day -Hour $hours -Minute $minutes -Second 0

        if ($endTime -le $now) {
            $endTime = $endTime.AddDays(1)
        }

        $script:EndTime = $endTime
        $script:ShutdownAfter = $shutdownCheckbox.Checked
        $timeFormat = $endTime.ToString("HH:mm:ss")
        $endTimeStatusLabel.Text = "Endzeit: $timeFormat"
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Fehler beim Setzen der Endzeit: $_",
            "Fehler",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
})

$form.Controls.Add($titleLabel)
$form.Controls.Add($statusLabel)
$form.Controls.Add($button)
$form.Controls.Add($endTimeLabel)
$form.Controls.Add($hoursLabel)
$form.Controls.Add($hoursInput)
$form.Controls.Add($minutesLabel)
$form.Controls.Add($minutesInput)
$form.Controls.Add($setEndTimeButton)
$form.Controls.Add($endTimeStatusLabel)
$form.Controls.Add($shutdownCheckbox)

$moveTimer = New-Object System.Windows.Forms.Timer
$moveTimer.Interval = [Math]::Max(50, $MoveIntervalMilliseconds)
$moveTimer.Add_Tick({
    if ($script:IsPressingButton) {
        return
    }

    $point = New-Object MouseJigglerNative+POINT
    if ([MouseJigglerNative]::GetCursorPos([ref]$point)) {
        [void][MouseJigglerNative]::SetCursorPos($point.X + ($Pixels * $script:Direction), $point.Y)
        Start-Sleep -Milliseconds 80
        [void][MouseJigglerNative]::SetCursorPos($point.X, $point.Y)
        $script:Direction *= -1
    }
})

$pressTimer = New-Object System.Windows.Forms.Timer
$pressTimer.Interval = [Math]::Max(1, $PressIntervalSeconds) * 1000
$pressTimer.Add_Tick({
    $script:IsPressingButton = $true

    try {
        $form.Activate()
        $button.Focus()

        $buttonCenter = New-Object System.Drawing.Point(
            [int]($button.Width / 2),
            [int]($button.Height / 2)
        )
        $screenPoint = $button.PointToScreen($buttonCenter)

        [void][MouseJigglerNative]::SetCursorPos($screenPoint.X, $screenPoint.Y)
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 80

        $currentPoint = New-Object MouseJigglerNative+POINT
        if (-not [MouseJigglerNative]::GetCursorPos([ref]$currentPoint)) {
            return
        }

        $buttonBounds = New-Object System.Drawing.Rectangle(
            $button.PointToScreen([System.Drawing.Point]::Empty),
            $button.Size
        )

        if (-not $buttonBounds.Contains($currentPoint.X, $currentPoint.Y)) {
            return
        }

        [MouseJigglerNative]::mouse_event($mouseEventLeftDown, 0, 0, 0, [UIntPtr]::Zero)
        Start-Sleep -Milliseconds 120
        [MouseJigglerNative]::mouse_event($mouseEventLeftUp, 0, 0, 0, [UIntPtr]::Zero)
    }
    finally {
        $script:IsPressingButton = $false
    }
})

$endTimeTimer = New-Object System.Windows.Forms.Timer
$endTimeTimer.Interval = 1000
$endTimeTimer.Add_Tick({
    if ($script:EndTime -ne $null) {
        $now = Get-Date
        if ($now -ge $script:EndTime) {
            $moveTimer.Stop()
            $pressTimer.Stop()
            $endTimeTimer.Stop()

            if ($script:ShutdownAfter) {
                [System.Windows.Forms.MessageBox]::Show(
                    "Endzeit erreicht! Der Computer wird in 60 Sekunden heruntergefahren.`nDas kann mit 'shutdown /a' im Terminal abgebrochen werden.",
                    "Endzeit erreicht",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
                Start-Process "shutdown" -ArgumentList "/s /t 60 /c `"MouseJiggler Endzeit erreicht`""
            }
            else {
                [System.Windows.Forms.MessageBox]::Show(
                    "Endzeit erreicht! Das Programm wird beendet.",
                    "Endzeit erreicht",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
            }

            $form.Close()
        }
    }
})

$form.Add_Shown({
    $moveTimer.Start()
    $pressTimer.Start()
    $endTimeTimer.Start()
})

$form.Add_KeyDown({
    param($sender, $eventArgs)

    if ($eventArgs.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
        $form.Close()
    }
})

$form.Add_FormClosed({
    $moveTimer.Stop()
    $pressTimer.Stop()
    $endTimeTimer.Stop()
    $moveTimer.Dispose()
    $pressTimer.Dispose()
    $endTimeTimer.Dispose()
})

[void][System.Windows.Forms.Application]::Run($form)

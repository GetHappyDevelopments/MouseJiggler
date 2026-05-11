param(
    [Alias("IntervalSeconds")]
    [int]$PressIntervalSeconds = 5,
    [int]$MoveIntervalMilliseconds = 1000,
    [int]$Pixels = 1,
    [string]$EndTime = $null,
    [Nullable[int]]$EndTimeHours = $null,
    [Nullable[int]]$EndTimeMinutes = $null,
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
$script:IsPaused = $false
$script:PressCount = 0
$script:EndDateTime = $null
$script:ShutdownAfter = $ShutdownAfter

function Format-Countdown {
    param(
        [TimeSpan]$Remaining
    )

    if ($Remaining -lt [TimeSpan]::Zero) {
        $Remaining = [TimeSpan]::Zero
    }

    $totalHours = [int][Math]::Floor($Remaining.TotalHours)
    return "{0:00}:{1:00}:{2:00}" -f $totalHours, $Remaining.Minutes, $Remaining.Seconds
}

function Get-NextEndTime {
    param(
        [int]$Hours,
        [int]$Minutes
    )

    $now = Get-Date
    $endTime = Get-Date -Year $now.Year -Month $now.Month -Day $now.Day -Hour $Hours -Minute $Minutes -Second 0

    if ($endTime -le $now) {
        $endTime = $endTime.AddDays(1)
    }

    return $endTime
}

function Try-ParseEndTime {
    param(
        [string]$Text,
        [ref]$Hours,
        [ref]$Minutes
    )

    $match = [regex]::Match($Text.Trim(), "^(?<hours>[0-2][0-9]):(?<minutes>[0-5][0-9])$")

    if (-not $match.Success) {
        return $false
    }

    $parsedHours = [int]$match.Groups["hours"].Value
    $parsedMinutes = [int]$match.Groups["minutes"].Value

    if ($parsedHours -gt 23) {
        return $false
    }

    $Hours.Value = $parsedHours
    $Minutes.Value = $parsedMinutes
    return $true
}

function Update-EndTimeDisplay {
    if ($script:EndDateTime -eq $null) {
        $endTimeStatusLabel.Text = "Keine Endzeit gesetzt."
        $countdownValueLabel.Text = "--:--:--"
        return
    }

    $remaining = $script:EndDateTime - (Get-Date)
    $endTimeStatusLabel.Text = "Ende: $($script:EndDateTime.ToString("HH:mm"))"
    $countdownValueLabel.Text = Format-Countdown -Remaining $remaining
}

function Set-EndTimeFromInput {
    try {
        $hours = 0
        $minutes = 0

        if (-not (Try-ParseEndTime -Text $endTimeInput.Text -Hours ([ref]$hours) -Minutes ([ref]$minutes))) {
            [System.Windows.Forms.MessageBox]::Show(
                "Bitte geben Sie eine gueltige Uhrzeit im Format HH:MM an, zum Beispiel 18:30.",
                "Ungueltige Uhrzeit",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            )
            return
        }

        $script:EndDateTime = Get-NextEndTime -Hours $hours -Minutes $minutes
        $script:ShutdownAfter = $shutdownCheckbox.Checked
        Update-EndTimeDisplay
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Fehler beim Setzen der Endzeit: $_",
            "Fehler",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
}

function Start-SystemShutdown {
    $shutdownPath = Join-Path $env:SystemRoot "System32\shutdown.exe"

    if (-not (Test-Path -LiteralPath $shutdownPath)) {
        $shutdownPath = "shutdown.exe"
    }

    Start-Process -FilePath $shutdownPath -ArgumentList '/s /t 60 /c "MouseJiggler Endzeit erreicht"' -WindowStyle Hidden
}

[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = "MouseJiggler"
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $true
$form.ClientSize = New-Object System.Drawing.Size(380, 360)
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

$pauseButton = New-Object System.Windows.Forms.Button
$pauseButton.Text = "Pausieren"
$pauseButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$pauseButton.Size = New-Object System.Drawing.Size(120, 30)
$pauseButton.Location = New-Object System.Drawing.Point(130, 146)

$pauseStatusLabel = New-Object System.Windows.Forms.Label
$pauseStatusLabel.Text = "Aktiv"
$pauseStatusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$pauseStatusLabel.AutoSize = $true
$pauseStatusLabel.Location = New-Object System.Drawing.Point(26, 153)

$pauseButton.Add_Click({
    $script:IsPaused = -not $script:IsPaused

    if ($script:IsPaused) {
        $moveTimer.Stop()
        $pressTimer.Stop()
        $pauseButton.Text = "Fortsetzen"
        $pauseStatusLabel.Text = "Pausiert"
        $titleLabel.Text = "MouseJiggler pausiert"
    }
    else {
        $moveTimer.Start()
        $pressTimer.Start()
        $pauseButton.Text = "Pausieren"
        $pauseStatusLabel.Text = "Aktiv"
        $titleLabel.Text = "MouseJiggler laeuft"
    }
})

$endTimeLabel = New-Object System.Windows.Forms.Label
$endTimeLabel.Text = "Endzeit als Uhrzeit (optional):"
$endTimeLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$endTimeLabel.AutoSize = $true
$endTimeLabel.Location = New-Object System.Drawing.Point(26, 194)

$endTimeInputLabel = New-Object System.Windows.Forms.Label
$endTimeInputLabel.Text = "Uhrzeit (HH:MM):"
$endTimeInputLabel.AutoSize = $true
$endTimeInputLabel.Location = New-Object System.Drawing.Point(26, 222)

$endTimeInput = New-Object System.Windows.Forms.TextBox
$endTimeInput.Width = 70
$endTimeInput.Location = New-Object System.Drawing.Point(135, 219)
$endTimeInput.Text = (Get-Date).AddHours(1).ToString("HH:mm")

$setEndTimeButton = New-Object System.Windows.Forms.Button
$setEndTimeButton.Text = "Endzeit setzen"
$setEndTimeButton.Size = New-Object System.Drawing.Size(100, 28)
$setEndTimeButton.Location = New-Object System.Drawing.Point(26, 250)

$endTimeStatusLabel = New-Object System.Windows.Forms.Label
$endTimeStatusLabel.Text = "Keine Endzeit gesetzt."
$endTimeStatusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$endTimeStatusLabel.AutoSize = $true
$endTimeStatusLabel.Location = New-Object System.Drawing.Point(135, 256)

$countdownLabel = New-Object System.Windows.Forms.Label
$countdownLabel.Text = "Countdown:"
$countdownLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$countdownLabel.AutoSize = $true
$countdownLabel.Location = New-Object System.Drawing.Point(26, 292)

$countdownValueLabel = New-Object System.Windows.Forms.Label
$countdownValueLabel.Text = "--:--:--"
$countdownValueLabel.Font = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Bold)
$countdownValueLabel.AutoSize = $true
$countdownValueLabel.Location = New-Object System.Drawing.Point(135, 288)

$shutdownCheckbox = New-Object System.Windows.Forms.CheckBox
$shutdownCheckbox.Text = "Computer herunterfahren"
$shutdownCheckbox.AutoSize = $true
$shutdownCheckbox.Location = New-Object System.Drawing.Point(26, 326)
$shutdownCheckbox.Checked = $ShutdownAfter

$setEndTimeButton.Add_Click({
    Set-EndTimeFromInput
})

$form.Controls.Add($titleLabel)
$form.Controls.Add($statusLabel)
$form.Controls.Add($button)
$form.Controls.Add($pauseButton)
$form.Controls.Add($pauseStatusLabel)
$form.Controls.Add($endTimeLabel)
$form.Controls.Add($endTimeInputLabel)
$form.Controls.Add($endTimeInput)
$form.Controls.Add($setEndTimeButton)
$form.Controls.Add($endTimeStatusLabel)
$form.Controls.Add($countdownLabel)
$form.Controls.Add($countdownValueLabel)
$form.Controls.Add($shutdownCheckbox)

$moveTimer = New-Object System.Windows.Forms.Timer
$moveTimer.Interval = [Math]::Max(50, $MoveIntervalMilliseconds)
$moveTimer.Add_Tick({
    if ($script:IsPaused) {
        return
    }

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
    if ($script:IsPaused) {
        return
    }

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
    if ($script:EndDateTime -ne $null) {
        $now = Get-Date
        Update-EndTimeDisplay

        if ($now -ge $script:EndDateTime) {
            $moveTimer.Stop()
            $pressTimer.Stop()
            $endTimeTimer.Stop()

            if ($script:ShutdownAfter) {
                try {
                    Start-SystemShutdown

                    [System.Windows.Forms.MessageBox]::Show(
                        "Endzeit erreicht! Der Computer wird in 60 Sekunden heruntergefahren.`nDas kann mit 'shutdown /a' im Terminal abgebrochen werden.",
                        "Endzeit erreicht",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Information
                    )
                }
                catch {
                    [System.Windows.Forms.MessageBox]::Show(
                        "Endzeit erreicht, aber das Herunterfahren konnte nicht gestartet werden: $_",
                        "Fehler beim Herunterfahren",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Error
                    )
                }
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
    if (-not [string]::IsNullOrWhiteSpace($EndTime)) {
        $endTimeInput.Text = $EndTime
        Set-EndTimeFromInput
    }
    elseif ($EndTimeHours -ne $null) {
        $endTimeInput.Text = "{0:00}:{1:00}" -f $EndTimeHours, ([int]$EndTimeMinutes)
        Set-EndTimeFromInput
    }

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

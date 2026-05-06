param(
    [Alias("IntervalSeconds")]
    [int]$PressIntervalSeconds = 5,
    [int]$MoveIntervalMilliseconds = 1000,
    [int]$Pixels = 1
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

[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = "MouseJiggler"
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $true
$form.ClientSize = New-Object System.Drawing.Size(360, 170)
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

$form.Controls.Add($titleLabel)
$form.Controls.Add($statusLabel)
$form.Controls.Add($button)

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

$form.Add_Shown({
    $moveTimer.Start()
    $pressTimer.Start()
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
    $moveTimer.Dispose()
    $pressTimer.Dispose()
})

[void][System.Windows.Forms.Application]::Run($form)

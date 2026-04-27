param(
    [int]$IntervalSeconds = 20,
    [int]$Pixels = 1
)

$ErrorActionPreference = "Stop"

$signature = @"
using System;
using System.Runtime.InteropServices;

public static class MouseTremorNative
{
    [DllImport("user32.dll")]
    public static extern bool GetCursorPos(out POINT lpPoint);

    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int X, int Y);

    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);

    public struct POINT
    {
        public int X;
        public int Y;
    }
}
"@

Add-Type -TypeDefinition $signature

$escKey = 0x1B
$direction = 1

Write-Host "MouseTremor läuft. Drücke ESC zum Beenden."
Write-Host "Intervall: $IntervalSeconds Sekunden, Bewegung: $Pixels Pixel."

try {
    while ($true) {
        if (([MouseTremorNative]::GetAsyncKeyState($escKey) -band 0x8000) -ne 0) {
            break
        }

        $point = New-Object MouseTremorNative+POINT
        if ([MouseTremorNative]::GetCursorPos([ref]$point)) {
            [void][MouseTremorNative]::SetCursorPos($point.X + ($Pixels * $direction), $point.Y)
            Start-Sleep -Milliseconds 80
            [void][MouseTremorNative]::SetCursorPos($point.X, $point.Y)
            $direction *= -1
        }

        $slept = 0
        while ($slept -lt $IntervalSeconds) {
            if (([MouseTremorNative]::GetAsyncKeyState($escKey) -band 0x8000) -ne 0) {
                break 2
            }

            Start-Sleep -Milliseconds 250
            $slept += 0.25
        }
    }
}
finally {
    Write-Host "MouseTremor beendet."
}

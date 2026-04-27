# MouseTremor

Kleines Windows-Programm, das den Mauszeiger regelmäßig minimal bewegt und mit `ESC` beendet wird.

## Starten

Doppelklick auf:

```text
Start-MouseTremor.bat
```

Oder direkt in PowerShell:

```powershell
.\MouseTremor.ps1
```

## Optionen

```powershell
.\MouseTremor.ps1 -IntervalSeconds 20 -Pixels 1
```

- `IntervalSeconds`: Abstand zwischen den Bewegungen.
- `Pixels`: Größe der kurzen Bewegung.

Zum Beenden jederzeit `ESC` drücken.

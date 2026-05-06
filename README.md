# MouseJiggler

Kleine Windows-Dialoganwendung, die den Mauszeiger regelmaessig minimal bewegt. Alle paar Sekunden setzt die Anwendung den Mauszeiger auf den Button und drueckt ihn per linkem Mausklick.

Die Mausbewegung pausiert, waehrend der Button gedrueckt wird.

## Starten

Doppelklick auf:

```text
Start-MouseJiggler.bat
```

Oder direkt in PowerShell:

```powershell
.\MouseJiggler.ps1
```

## Optionen

```powershell
.\MouseJiggler.ps1 -PressIntervalSeconds 5 -MoveIntervalMilliseconds 1000 -Pixels 1
```

- `PressIntervalSeconds`: Abstand zwischen den automatischen Button-Druecken.
- `MoveIntervalMilliseconds`: Abstand zwischen den kurzen Mausbewegungen.
- `Pixels`: Groesse der kurzen Bewegung.

Zum Beenden das Fenster schliessen oder `ESC` druecken.

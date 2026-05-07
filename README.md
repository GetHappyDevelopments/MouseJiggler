# MouseJiggler

Kleine Windows-Dialoganwendung, die den Mauszeiger regelmaessig minimal bewegt. Alle paar Sekunden setzt die Anwendung den Mauszeiger auf den Button und drueckt ihn per linkem Mausklick.

Die Mausbewegung pausiert, waehrend der Button gedrueckt wird.

Die Anwendung kann mit einer Endzeit konfiguriert werden, nach der sie sich automatisch beendet. Optional kann der Computer auch automatisch heruntergefahren werden.

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
.\MouseJiggler.ps1 -PressIntervalSeconds 5 -MoveIntervalMilliseconds 1000 -Pixels 1 -EndTimeHours 18 -EndTimeMinutes 30 -ShutdownAfter $true
```

- `PressIntervalSeconds`: Abstand zwischen den automatischen Button-Druecken.
- `MoveIntervalMilliseconds`: Abstand zwischen den kurzen Mausbewegungen.
- `Pixels`: Groesse der kurzen Bewegung.
- `EndTimeHours`: (Optional) Stunden der Endzeit (0-23). Wenn nicht gesetzt, wird keine automatische Beendigung durchgefuehrt.
- `EndTimeMinutes`: (Optional) Minuten der Endzeit (0-59).
- `ShutdownAfter`: (Optional) Wenn $true, wird der Computer nach Erreichen der Endzeit heruntergefahren.

## Endzeit in der GUI setzen

In der Anwendungsfenster koennen Sie:
1. Stunden und Minuten eingeben
2. "Endzeit setzen" anklicken
3. Optional das Kontrollkaestchen "Computer herunterfahren" aktivieren
4. Das Programm beendet sich automatisch zur eingestellten Zeit

Das Herunterfahren kann mit `shutdown /a` im Terminal abgebrochen werden.

## Beenden

Das Fenster schliessen oder `ESC` druecken.


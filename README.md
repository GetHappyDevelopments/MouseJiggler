# MouseJiggler

Kleine Windows-Dialoganwendung, die den Mauszeiger regelmaessig minimal bewegt. Alle paar Sekunden setzt die Anwendung den Mauszeiger auf den Button und drueckt ihn per linkem Mausklick.

Die Mausbewegung pausiert, waehrend der Button gedrueckt wird. Ueber den Pause-Button kann die eigentliche MouseJiggler-Funktion jederzeit pausiert und wieder fortgesetzt werden, ohne die gesetzte Endzeit, den Countdown oder andere Einstellungen zu veraendern.

Die Anwendung kann mit einer konkreten Uhrzeit als Endzeit konfiguriert werden, nach der sie sich automatisch beendet. Sobald eine Endzeit gesetzt ist, wird ein Countdown angezeigt. Optional kann der Computer auch automatisch heruntergefahren werden.

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
.\MouseJiggler.ps1 -PressIntervalSeconds 5 -MoveIntervalMilliseconds 1000 -Pixels 1 -EndTime 18:30 -ShutdownAfter $true
```

- `PressIntervalSeconds`: Abstand zwischen den automatischen Button-Druecken.
- `MoveIntervalMilliseconds`: Abstand zwischen den kurzen Mausbewegungen.
- `Pixels`: Groesse der kurzen Bewegung.
- `EndTime`: (Optional) Konkrete Uhrzeit im Format `HH:MM`, zum Beispiel `18:30`. Wenn nicht gesetzt, wird keine automatische Beendigung durchgefuehrt.
- `EndTimeHours` / `EndTimeMinutes`: (Optional) Aeltere Alternative zu `EndTime`; `EndTime` ist die empfohlene Schreibweise.
- `ShutdownAfter`: (Optional) Wenn $true, wird der Computer nach Erreichen der Endzeit heruntergefahren.

## Endzeit in der GUI setzen

Im Anwendungsfenster koennen Sie:
1. Die gewuenschte Uhrzeit im Format `HH:MM` eingeben
2. "Endzeit setzen" anklicken
3. Optional das Kontrollkaestchen "Computer herunterfahren" aktivieren
4. Den Countdown bis zur eingestellten Uhrzeit verfolgen

Liegt die eingegebene Uhrzeit bereits in der Vergangenheit, wird automatisch die gleiche Uhrzeit am naechsten Tag verwendet.

## Pausieren

Mit "Pausieren" werden Mausbewegung und automatische Button-Druecke angehalten. Der Countdown laeuft weiter und die gesetzte Endzeit bleibt unveraendert. Mit "Fortsetzen" wird die MouseJiggler-Funktion wieder gestartet.

Das Herunterfahren kann mit `shutdown /a` im Terminal abgebrochen werden.

## Beenden

Das Fenster schliessen oder `ESC` druecken.

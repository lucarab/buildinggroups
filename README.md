## Inhaltsverzeichnis

1. [Überblick](#überblick)  
2. [Features](#features)  
3. [Verzeichnisstruktur](#verzeichnisstruktur)  
4. [Admin-Befehle](#admin-befehle)  

## Überblick

Mit dem DoorGroupSystem wird das Kaufen und Verkaufen ganzer Gebäude in DarkRP einfacher und übersichtlicher. Anstelle einzelner Türen werden nun Gruppen von Türen (in einem Gebäude) zusammengefasst. 

Das System erlaubt es Spielern, komplette Gebäude mit mehreren Türen auf einmal zu erwerben, anstatt jede Tür einzeln zu kaufen. Zudem bietet es eine einheitliche Verwaltung des Gebäudebesitzes, sodass keine einzelnen Türen innerhalb eines Gebäudes vergessen oder versehentlich verkauft werden können. Der Hauptbesitzer eines Gebäudes kann Mitbesitzer festlegen, die ebenfalls Zugang zu allen Türen des Gebäudes haben. Die Verwaltung der Co-Owner erfolgt wie gehabt einfach über das DarkRP-Menü oder Chat-Befehle.

## Features

- **Gebäude in Gruppen organisieren**: Fasse mehrere Türen zu einem "Building" zusammen.  
- **Zentraler Kauf**: Statt jede Tür einzeln zu kaufen, kauft man ein gesamtes Gebäude mit einem Klick (F2).  
- **Automatische Co-Owner-Verwaltung**: Wenn man Besitzer eines Gebäudes ist, ist man Besitzer aller dazugehörigen Türen.  
- **Optimierter HUD-Override**: Zeigt an, ob ein Gebäude gekauft, verkauft oder frei ist – inklusive Preis, Türanzahl etc.  
- **Einfaches Hinzufügen/Löschen** von Gebäuden, Türen und Preisen via Admin-Commands (Chat-Befehle).  
- **Konfigurierbare Preise und Steuern**: Stelle u. a. die Grundkosten, den Türfaktor und die PropertyTax ein.  
- **Hervorhebung von ungekauften Gebäuden**: Nicht gekaufte Gebäude werden visuell hervorgehoben, um die Übersicht zu verbessern.  
- **Serverweite Synchronisation**: Alle Spieler erhalten immer aktuelle Gebäudedaten, ohne dass ein manueller Reload notwendig ist.  
- **Unterstützung für DarkRP Permissions**: Admins haben die volle Kontrolle über das System und können Änderungen über Chat-Befehle verwalten.  
- **Dynamische Preisberechnung**: Preise passen sich an die Anzahl der Türen im Gebäude an, um faire Kaufpreise zu gewährleisten.  
- **Automatische Rückerstattung bei Verkauf**: Spieler erhalten einen anteiligen Betrag zurück, wenn sie ein Gebäude verkaufen.  
- **Flexibel erweiterbar**: Das System ist modular aufgebaut und kann leicht angepasst oder erweitert werden.  

## Verzeichnisstruktur

```
darkrp_modules/
└── buildinggroups/
    ├── sh_doorgroupsystem.lua    # Shared Code (Logik, Variablen, Funktionalität)
    ├── sv_doorgroupsystem.lua    # Server-seitige Funktionen (Speichern/Laden, Hooks, Chat-Commands)
    └── cl_doorgroupsystem.lua    # Client-seitige Funktionen (HUD, Halos, Net-Empfang)
```

## Admin-Befehle

```
/createbuilding "<Name>" <Grundpreis> <Türpreis>
```
Erstellt ein neues Gebäude.  

```
/setbuildingprice "<Name>" <NeuerGrundpreis> <NeuerTürpreis>
```
Setzt nachträglich die Preise für ein vorhandenes Gebäude.

```
/adddoor "<Name>"
```
Fügt die von dir aktuell anvisierte Tür (wohin du mit deinem Fadenkreuz schaust) einem bereits existierenden Gebäude hinzu.

```
/deletebuilding "<Name>"
```
Löscht ein Gebäude vollständig (inklusive seiner Türen-Zuordnung).

```
/renamebuilding "<AlterName>" "<NeuerName>"
```
Ändert den Namen eines bestehenden Gebäudes (die Zuordnung der Türen bleibt erhalten).

```
/reloadbuildings
```
Lädt die Gebäudedaten neu von der gespeicherten Datei (nützlich nach Bearbeitungen).

```
/sellalldoors
```
Verkauft alle Gebäude, die du besitzt (gibt 50% des Kaufpreises zurück).

```
/unownalldoors
```
Identisch zu `/sellalldoors` (Alias).
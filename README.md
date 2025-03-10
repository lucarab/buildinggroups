## Inhaltsverzeichnis

1. [Überblick](#überblick)  
2. [Features](#features)  
4. [Verzeichnisstruktur](#verzeichnisstruktur)  
5. [Admin-Befehle](#admin-befehle)  
6. [Wie man ein Gebäude kauft/verkauft](#wie-man-ein-gebäude-kauftverkauft)  

## Überblick

Mit dem DoorGroupSystem wird das Kaufen und Verkaufen ganzer Gebäude in DarkRP einfacher und übersichtlicher. Anstelle einzelner Türen werden nun Gruppen von Türen (in einem Gebäude) zusammengefasst.

**Beispiel:** Wenn ein Gebäude 5 Türen besitzt, kann ein Spieler diese 5 Türen mit nur einem Kauf erwerben und ist dann gleichzeitig Besitzer aller Türen in diesem Gebäude.

## Features

- **Gebäude in Gruppen organisieren**: Fasse mehrere Türen zu einem "Building" zusammen.  
- **Zentraler Kauf**: Statt jede Tür einzeln zu kaufen, kauft man ein gesamtes Gebäude mit einem Klick (F2).  
- **Automatische Co-Owner-Verwaltung**: Wenn man Besitzer eines Gebäudes ist, ist man Besitzer aller dazugehörigen Türen.  
- **Optimierter HUD-Override**: Zeigt an, ob ein Gebäude gekauft, verkauft oder frei ist – inklusive Preis, Türanzahl etc.  
- **Einfaches Hinzufügen/Löschen** von Gebäuden, Türen und Preisen via Admin-Commands (Chat-Befehle).  
- **Konfigurierbare Preise und Steuern**: Stelle u. a. die Grundkosten, den Türfaktor und die PropertyTax ein.  

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

## Wie man ein Gebäude kauft/verkauft

- **Gebäude kaufen**:
  1. Schaue auf eine Tür, die einem definierten Gebäude angehört.
  2. Drücke **F2** (Standard DarkRP Key) → Du erhältst eine Meldung über den Gesamtpreis des Gebäudes.
  3. Wenn du genug Geld hast, kaufst du damit alle zugehörigen Türen gleichzeitig.

- **Gebäude verkaufen**:
  1. Drücke ebenfalls **F2** auf eine Tür, die du besitzt.
  2. Bestätige den Verkauf im Menü (oder nutze `/sellalldoors`).
  3. Du erhältst automatisch 50 % des Kaufpreises zurück.

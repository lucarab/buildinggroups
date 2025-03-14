## DEMO Video

https://youtu.be/CqJbftWCQlw

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
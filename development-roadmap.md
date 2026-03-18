# Comic-Archiv - Development Roadmap

## 🎯 Übersicht

Diese Roadmap zeigt dir Schritt für Schritt, wie wir die Comic-Archiv App entwickeln. Jede Phase baut auf der vorherigen auf und liefert lauffähige Ergebnisse.

---

## 📅 Phase 1: Projekt-Setup & Grundgerüst
**Ziel:** Lauffähige App mit Basis-UI  
**Dauer:** 1-2 Sessions

### 1.1 Xcode Projekt erstellen
- [ ] Neues Xcode Projekt: "ComicArchiv"
- [ ] Type: macOS App
- [ ] Interface: SwiftUI
- [ ] Language: Swift
- [ ] Storage: SwiftData (oder Core Data)

### 1.2 Projekt-Struktur aufsetzen
- [ ] Ordner erstellen: Models, Views, ViewModels, Services
- [ ] Basis-Dateien anlegen

### 1.3 Datenmodelle erstellen
- [ ] `Comic.swift` - Struktur für einen Comic
- [ ] `ComicListe.swift` - Struktur für eine Liste
- [ ] Dummy-Daten zum Testen erstellen

### 1.4 Basis-Layout bauen
- [ ] `MainView.swift` - Haupt-Container
- [ ] `SidebarView.swift` - Listen-Sidebar (links)
- [ ] `ComicGridView.swift` - Comic-Anzeige (rechts)
- [ ] Split-View Layout implementieren

### ✅ Meilenstein 1
App startet und zeigt:
- Sidebar mit Dummy-Listen
- Grid mit Dummy-Comics
- Noch keine Interaktion

**Test:** App läuft, UI ist sichtbar

---

## 📅 Phase 2: Daten-Management
**Ziel:** Comics und Listen verwalten  
**Dauer:** 2-3 Sessions

### 2.1 ViewModel & State Management
- [ ] `ComicViewModel.swift` - Zentrale Daten-Logik
- [ ] ObservableObject implementieren
- [ ] @Published Properties für Comics und Listen

### 2.2 Comic hinzufügen
- [ ] "Comic hinzufügen" Button
- [ ] Sheet/Modal für neuen Comic
- [ ] Formular mit allen Feldern
- [ ] Comic zur Liste hinzufügen

### 2.3 Comic bearbeiten & löschen
- [ ] Comic-Detail-View
- [ ] Daten editieren
- [ ] Änderungen speichern
- [ ] Comic löschen mit Bestätigung

### 2.4 Listen-Management
- [ ] "Neue Liste" Button
- [ ] Liste erstellen (Name eingeben)
- [ ] Liste umbenennen
- [ ] Liste löschen (außer "Meine Sammlung")
- [ ] Liste auswählen → Comics filtern

### ✅ Meilenstein 2
- Comics erstellen, bearbeiten, löschen
- Listen erstellen, umbenennen, löschen
- Comics werden der richtigen Liste zugeordnet
- Daten bleiben während App-Laufzeit erhalten

**Test:** Alle CRUD-Operationen funktionieren

---

## 📅 Phase 3: Datenpersistenz
**Ziel:** Daten bleiben gespeichert  
**Dauer:** 1-2 Sessions

### 3.1 SwiftData/Core Data einrichten
- [ ] Persistenz-Layer implementieren
- [ ] `DataManager.swift` - Speicher-Logik
- [ ] Daten beim Start laden
- [ ] Daten bei Änderungen speichern

### 3.2 Migration & Testing
- [ ] Testen: App beenden und neu starten
- [ ] Daten bleiben erhalten
- [ ] Fehlerbehandlung für Speicher-Fehler

### ✅ Meilenstein 3
- Alle Daten persistent gespeichert
- App-Neustart → Daten sind noch da
- Stabil und zuverlässig

**Test:** App beenden, neu starten, Daten da

---

## 📅 Phase 4: Drag & Drop
**Ziel:** Comics zwischen Listen verschieben  
**Dauer:** 2-3 Sessions

### 4.1 Drag-Funktionalität
- [ ] Comics als "draggable" markieren
- [ ] Drag-Daten (Comic-ID) übergeben
- [ ] Visuelles Feedback beim Ziehen

### 4.2 Drop-Funktionalität
- [ ] Listen als Drop-Ziele
- [ ] Drop-Handler implementieren
- [ ] Comic zur Ziel-Liste hinzufügen

### 4.3 UX-Verbesserungen
- [ ] Drop-Zone visuell hervorheben
- [ ] Animationen beim Drop
- [ ] Feedback bei erfolgreichem Drop

### ✅ Meilenstein 4
- Comics können per Drag & Drop verschoben werden
- Intuitive Bedienung
- Visuelles Feedback

**Test:** Comic von Liste A nach B ziehen

---

## 📅 Phase 5: Cover-Bilder
**Ziel:** Bilder hochladen und anzeigen  
**Dauer:** 2-3 Sessions

### 5.1 Bild-Upload
- [ ] "Cover-Bild hinzufügen" Button
- [ ] File-Picker für Bilder
- [ ] Bild-Validierung (Format, Größe)

### 5.2 Bild-Speicherung
- [ ] `ImageManager.swift` - Bild-Verwaltung
- [ ] Bilder lokal speichern (Documents-Ordner)
- [ ] Referenz in Comic-Daten

### 5.3 Bild-Anzeige
- [ ] Cover in Comic-Karte (Grid)
- [ ] Größeres Cover in Detail-View
- [ ] Placeholder für Comics ohne Cover
- [ ] Thumbnail-Generierung (optional)

### 5.4 Bild-Verwaltung
- [ ] Cover-Bild ändern
- [ ] Cover-Bild löschen
- [ ] Speicher-Management (alte Bilder löschen)

### ✅ Meilenstein 5
- Cover-Bilder hochladbar
- Bilder werden angezeigt
- Speichert Bilder persistent
- Platzhalter für fehlende Cover

**Test:** Bild hochladen, App neu starten, Bild da

---

## 📅 Phase 6: Polish & UI-Verbesserungen
**Ziel:** App professionell gestalten  
**Dauer:** 2-3 Sessions

### 6.1 UI-Feinschliff
- [ ] Spacing, Padding optimieren
- [ ] Farben und Fonts anpassen
- [ ] Icons für Listen (SF Symbols)
- [ ] Toolbar-Items optimieren

### 6.2 Animationen & Transitions
- [ ] View-Übergänge smooth
- [ ] Hover-Effekte
- [ ] Gelesen-Status Animation

### 6.3 Gelesen-Status System
- [ ] Status-Toggle in Detail-View
- [ ] Visueller Indikator in Grid (Badge/Icon)
- [ ] Filter: Gelesen/Ungelesen (später)

### 6.4 Fehlerbehandlung & Edge Cases
- [ ] Leere Listen-Ansicht
- [ ] Keine Comics vorhanden
- [ ] Fehler beim Bild-Upload
- [ ] Bestätigungsdialoge

### 6.5 App-Icon & Branding
- [ ] App-Icon erstellen
- [ ] About-Screen (optional)

### ✅ Meilenstein 6
- App sieht professionell aus
- Smooth Animationen
- Alle Edge Cases behandelt
- Ready to use!

**Test:** Gesamte App durchgehen, auf Details achten

---

## 🚀 Zukünftige Erweiterungen (Post-Launch)

### Optional - Wenn Basis-App fertig:

#### Suchfunktion
- [ ] Suchfeld in Toolbar
- [ ] Nach Titel, Autor, Verlag suchen
- [ ] Live-Suche während Eingabe

#### Filter & Sortierung
- [ ] Filter nach Verlag, Gelesen-Status
- [ ] Sortierung (Titel, Datum, Autor)
- [ ] Multi-Filter kombinieren

#### Export-Funktionen
- [ ] Liste als CSV exportieren
- [ ] PDF-Report generieren
- [ ] Statistiken anzeigen

#### Erweiterte Features
- [ ] Bewertungssystem (Sterne)
- [ ] Notizen pro Comic
- [ ] Tags/Labels
- [ ] Duplikat-Erkennung
- [ ] Import aus CSV

#### Cloud & Sync
- [ ] iCloud Sync
- [ ] Backup/Restore Funktion

---

## 📊 Aktueller Fortschritt

**Phase 1:** ⬜️ Noch nicht gestartet  
**Phase 2:** ⬜️ Noch nicht gestartet  
**Phase 3:** ⬜️ Noch nicht gestartet  
**Phase 4:** ⬜️ Noch nicht gestartet  
**Phase 5:** ⬜️ Noch nicht gestartet  
**Phase 6:** ⬜️ Noch nicht gestartet

---

## 💡 Arbeits-Prinzipien

**"Vibe Coding" mit Claude:**
1. **Eine Phase nach der anderen** - Nicht überspringen!
2. **Testen nach jedem Schritt** - Stelle sicher es funktioniert
3. **Feedback geben** - "Funktioniert!", "Fehler:", "Anders machen:"
4. **Iterieren** - Erst funktional, dann schön
5. **Fragen stellen** - Bei Unklarheiten nachfragen

**Typischer Workflow:**
```
Du: "Lass uns Phase 1.1 starten - Projekt erstellen"
Claude: [Anleitung + Code]
Du: [Erstellt Projekt, testet]
Du: "Funktioniert! Weiter zu 1.2"
Claude: [Nächster Schritt]
...
```

**Bei Problemen:**
```
Du: "Fehler: [Fehlermeldung]"
Claude: [Analysiert, gibt Lösung]
Du: [Testet Lösung]
Du: "Fixed!" oder "Anderer Fehler:"
```

---

**Viel Erfolg! 🎨📚 Lass uns eine großartige App bauen!**
